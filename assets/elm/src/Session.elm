module Session exposing (Error(..), Payload, Session, decodeToken, fetchNewToken, init, propagateToken, request)

import Http
import Json.Decode as Decode exposing (field)
import Json.Decode.Pipeline as Pipeline
import Ports
import Task exposing (Task, fail, succeed)
import Time exposing (Posix)
import Vendor.Jwt as Jwt exposing (JwtError)



-- TYPES


type alias Payload =
    { iat : Int
    , exp : Int
    , sub : String
    }


type alias Session =
    { token : String
    , payload : Result JwtError Payload
    }


type Error
    = Expired
    | Invalid
    | HttpError Http.Error



-- API


{-| Accepts a JWT and generates a new Session record that contains the decoded
payload.

    init "ey..."
        == { token = "ey..."
           , payload = Ok { iat = 1517515691, exp = 1517515691, sub = "999999999" }
           }

    init "invalid"
        == { token = "invalid"
           , payload = Err (TokenProcessingError "Wrong length")
           }

-}
init : String -> Session
init token =
    Session token (decodeToken token)


{-| Accepts a token and returns a Result from attempting to decode the payload.

    decodeToken "ey..." == Ok { iat = 1517515691, exp = 1517515691, sub = "999999999" }

    decodeToken "invalid" == Err (TokenProcessingError "Wrong length")

-}
decodeToken : String -> Result JwtError Payload
decodeToken token =
    let
        decoder =
            Decode.succeed Payload
                |> Pipeline.required "iat" Decode.int
                |> Pipeline.required "exp" Decode.int
                |> Pipeline.required "sub" Decode.string
    in
    Jwt.decodeToken decoder token


{-| Builds a request for fetching a new JWT. This request should succeed if
there a valid cookie-based session.
-}
fetchNewToken : Session -> Task Error Session
fetchNewToken session =
    let
        tokenRequest =
            Http.post "/api/tokens" Http.emptyBody <|
                Decode.map init (field "token" Decode.string)
    in
    tokenRequest
        |> Http.toTask
        |> Task.mapError handleError


{-| Builds a `Task` that refreshes the `Session` if it has expired, then
executes the given request with that session.
-}
request : Session -> (Session -> Http.Request a) -> Task Error ( Session, a )
request session innerRequest =
    Time.now
        |> Task.andThen (refreshIfExpired session)
        |> Task.andThen (performRequest innerRequest)


{-| Propagates a token to the websocket connection.
-}
propagateToken : Session -> Cmd msg
propagateToken { token } =
    Ports.updateToken token



-- INTERNAL


refreshIfExpired : Session -> Posix -> Task Error Session
refreshIfExpired session now =
    case session.payload of
        Ok payload ->
            if payload.exp <= inSeconds now then
                fetchNewToken session

            else
                succeed session

        _ ->
            fail Invalid


performRequest : (Session -> Http.Request a) -> Session -> Task Error ( Session, a )
performRequest innerRequest session =
    innerRequest session
        |> Http.toTask
        |> Task.mapError handleError
        |> Task.map (\a -> ( session, a ))


handleError : Http.Error -> Error
handleError error =
    case error of
        Http.BadStatus { status } ->
            if status.code == 401 || status.code == 403 then
                Expired

            else
                HttpError error

        _ ->
            HttpError error


inSeconds : Posix -> Int
inSeconds posix =
    posix
        |> Time.posixToMillis
        |> toFloat
        |> (/) 1000
        |> round
