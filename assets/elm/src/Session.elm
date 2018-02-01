module Session exposing (Session, Payload, init, decodeToken)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Jwt exposing (JwtError)


type alias Payload =
    { iat : Int
    , exp : Int
    , sub : String
    }


type alias Session =
    { token : String
    , payload : Result JwtError Payload
    }


{-| Accepts a JWT and generates a new Session record that contains the decoded
payload.

    init "ey..." ==
        { token = "ey..."
        , payload = Ok { iat = 1517515691, exp = 1517515691, sub = "999999999" }
        }

    init "invalid" ==
        { token = "invalid"
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
            Pipeline.decode Payload
                |> Pipeline.required "iat" Decode.int
                |> Pipeline.required "exp" Decode.int
                |> Pipeline.required "sub" Decode.string
    in
        Jwt.decodeToken decoder token
