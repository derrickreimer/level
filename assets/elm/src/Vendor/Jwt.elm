module Vendor.Jwt exposing
    ( decodeToken, tokenDecoder, isExpired, checkTokenExpiry
    , createRequest, createRequestObject, send, sendCheckExpired, get, post, put, delete
    , JwtError(..), promote401, handleError
    , authenticate
    )

{-| Helper functions for working with Jwt tokens and authenticated CRUD APIs.

This package provides functions for reading tokens, and for using them to make
authenticated Http requests.


# Token reading

@docs decodeToken, tokenDecoder, isExpired, checkTokenExpiry


# Authenticated Http requests

@docs createRequest, createRequestObject, send, sendCheckExpired, get, post, put, delete


# Error handlers

@docs JwtError, promote401, handleError


# Logging in

@docs authenticate

-}

import Debug
import Http exposing (Request, expectJson, header, jsonBody, request, toTask)
import Json.Decode as Json exposing (Value, field)
import String
import Task exposing (Task)
import Time exposing (Posix)
import Vendor.Base64 as Base64


{-| The following errors are modeled

  - Any Http.Error, other than a 401
  - 401 (Unauthorized), due either to token expiry or e.g. inadequate permissions
  - token (non-)expiry information
  - issues with processing (e.g. base 64 decoding) the token, and
  - problems decoding the json data within the content of the token

-}
type JwtError
    = HttpError Http.Error
    | Unauthorized
    | TokenExpired
    | TokenNotExpired
    | TokenProcessingError String
    | TokenDecodeError String



-- TOKEN PROCESSING


{-| decodeToken parses the token, checking that it meets the Jwt standards.

    decodeToken dec token

In the event of success, `decodeToken` returns an Elm record structure using the JSON Decoder.

-}
decodeToken : Json.Decoder a -> String -> Result JwtError a
decodeToken dec =
    getTokenBody
        >> Result.andThen (Base64.decode >> Result.mapError TokenDecodeError)
        >> Result.andThen (Json.decodeString dec >> Result.mapError (TokenDecodeError << Json.errorToString))


{-| All the token parsing goodness in the form of a Json Decoder

    -- decode token from Firebase
    let firebaseToken =
        decodeString
            (tokenDecoder Jwt.Decoders.firebase)
            tokenString

-}
tokenDecoder : Json.Decoder a -> Json.Decoder a
tokenDecoder inner =
    Json.string
        |> Json.andThen
            (\tokenStr ->
                let
                    transformedToken =
                        getTokenBody tokenStr
                            |> Result.mapError (\_ -> "parsing error")
                            |> Result.andThen Base64.decode
                            |> Result.mapError ((++) "base64 error: ")
                            |> Result.andThen (Json.decodeString inner >> Result.mapError Json.errorToString)
                in
                case transformedToken of
                    Ok val ->
                        Json.succeed val

                    Err err ->
                        Json.fail err
            )



-- Private helper functions


getTokenBody : String -> Result JwtError String
getTokenBody token =
    let
        processor =
            unurl >> String.split "." >> List.map fixlength
    in
    case processor token of
        _ :: (Result.Err e) :: _ :: [] ->
            Result.Err e

        _ :: (Result.Ok encBody) :: _ :: [] ->
            Result.Ok encBody

        _ ->
            Result.Err <| TokenProcessingError "Token has invalid shape"


unurl : String -> String
unurl =
    let
        fix c =
            case c of
                '-' ->
                    '+'

                '_' ->
                    '/'

                _ ->
                    c
    in
    String.map fix


fixlength : String -> Result JwtError String
fixlength s =
    case modBy 4 (String.length s) of
        0 ->
            Result.Ok s

        2 ->
            Result.Ok <| String.concat [ s, "==" ]

        3 ->
            Result.Ok <| String.concat [ s, "=" ]

        _ ->
            Result.Err <| TokenProcessingError "Wrong length"


{-| Checks a token for Expiry. Returns expiry or any errors that occurred in decoding.
-}
checkTokenExpiry : String -> Task Never JwtError
checkTokenExpiry token =
    Time.now
        |> Task.andThen (checkUnacceptedToken token >> Task.succeed)


{-| Checks whether a token has expired, and returns True or False, or
any error that occurred while decoding the token.
-}
isExpired : Posix -> String -> Result JwtError Bool
isExpired now token =
    decodeToken (field "exp" Json.float) token
        |> Result.map (\exp -> toFloat (Time.posixToMillis now) > exp * 1000)


checkUnacceptedToken : String -> Posix -> JwtError
checkUnacceptedToken token now =
    case isExpired now token of
        Result.Ok True ->
            TokenExpired

        Result.Ok False ->
            -- Although the token is not expired, server rejected request for some other reason
            TokenNotExpired

        Result.Err jwtErr ->
            -- Pass through a decoding error
            jwtErr



{- ====================================================
    MAKING AUTHENTICATED API CALLS
   ====================================================
-}


{-| createRequest creates a Http.Request with the token added to the headers, and
sets the `withCredentials` field to True.
-}
createRequest : String -> String -> String -> Http.Body -> Json.Decoder a -> Http.Request a
createRequest method token url body =
    createRequestObject method token url body >> request


{-| createRequestObject creates the data structure expected by Http.Request.
It is broken out here so that users can change the expect part in the event that
one of their REST apis does not return Json.

In my experience, the Authorization header is NOT case sensitive. Do raise an issue if you experience otherwise.

See [MDN](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/withCredentials) for more on withCredentials. The default is False.

-}
createRequestObject :
    String
    -> String
    -> String
    -> Http.Body
    -> Json.Decoder a
    -> { method : String, headers : List Http.Header, url : String, body : Http.Body, expect : Http.Expect a, timeout : Maybe Float, withCredentials : Bool }
createRequestObject method token url body dec =
    { method = method
    , headers = [ header "Authorization" ("Bearer " ++ token) ]
    , url = url
    , body = body
    , expect = expectJson dec
    , timeout = Nothing
    , withCredentials = False
    }


{-| `get` is a replacement for `Http.get` that returns a Http.Request with the token
attached to the headers.

    getData : String -> Cmd Msg
    getData token =
        Jwt.get token "/api/data" dataDecoder
            |> Jwt.send DataResult

-}
get : String -> String -> Json.Decoder a -> Request a
get token url dec =
    createRequest "GET" token url Http.emptyBody dec


{-| post is a replacement for `Http.post` that returns a Http.Request with the token
attached to the headers.

\*\* Note that is important to use jsonBody to ensure that the 'application/json' is added to the headers \*\*

    postContent : Token -> Json.Decoder a -> E.Value -> String -> Request a
    postContent token dec value url =
        Jwt.post token url (Http.jsonBody value) (phoenixDecoder dec)
            |> Jwt.send ContentResult

-}
post : String -> String -> Http.Body -> Json.Decoder a -> Request a
post =
    createRequest "POST"


{-| Create a PUT request with a token attached to the Authorization header
-}
put : String -> String -> Http.Body -> Json.Decoder a -> Request a
put =
    createRequest "PUT"


{-| returns a `DELETE` Http.Request with the token attached to the headers.
-}
delete : String -> String -> Json.Decoder a -> Request a
delete token url dec =
    createRequest "DELETE" token url Http.emptyBody dec


{-| `send` replaces `Http.send`. On receipt of a 401 error, it returns a Jwt.Unauthorized.
-}
send : (Result JwtError a -> msg) -> Request a -> Cmd msg
send msgCreator req =
    let
        conv : (Result JwtError a -> msg) -> (Result Http.Error a -> msg)
        conv fn =
            fn << Result.mapError promote401
    in
    Http.send (conv msgCreator) req


{-| `sendCheckExpired` is similar to `send` but, on receiving a 401, it carries out a further check to
determine whether the token has expired.
-}
sendCheckExpired : String -> (Result JwtError a -> msg) -> Request a -> Cmd msg
sendCheckExpired token msgCreator req =
    req
        |> toTask
        |> Task.map Result.Ok
        |> Task.onError (Task.map Err << handleError token)
        |> Task.perform msgCreator


{-| Takes an Http.Error. If it is a 401, then it checks the token for expiry.
-}
handleError : String -> Http.Error -> Task Never JwtError
handleError token err =
    case promote401 err of
        Unauthorized ->
            checkTokenExpiry token

        _ ->
            Task.succeed (HttpError err)


{-| Examines a 401 Unauthorized reponse, and converts the error to TokenExpired
when that is the case.

    getAuth : String -> String -> Json.Decoder a -> Task Never (Result JwtError a)
    getAuth token url dec =
        createRequest "GET" token url Http.emptyBody dec
            |> toTask
            |> Task.map Result.Ok
            |> Task.onError (promote401 token)

-}
promote401 : Http.Error -> JwtError
promote401 err =
    case err of
        Http.BadStatus { status } ->
            if status.code == 401 then
                Unauthorized

            else
                HttpError err

        _ ->
            HttpError err



{- ====================================================
    LOGGING IN - GETTING A TOKEN
   ====================================================
-}


{-| `authenticate` creates an Http.Request based on login credentials.
There is very little to this function (and it will be removed in future releases), so feel free to role your own here instead.

    submitCredentials : Model -> Cmd Msg
    submitCredentials model =
        E.object
            [ ( "username", E.string model.uname )
            , ( "password", E.string model.pword )
            ]
            |> authenticate "/sessions" tokenStringDecoder

-}
authenticate : String -> Json.Decoder a -> Value -> Request a
authenticate url dec credentials =
    Http.post url (jsonBody credentials) dec
