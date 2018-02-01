module Data.Session exposing (Session, Payload, init, payloadDecoder, decodeToken)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Jwt exposing (JwtError)


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


init : String -> Session
init token =
    Session token (decodeToken token)


payloadDecoder : Decode.Decoder Payload
payloadDecoder =
    Pipeline.decode Payload
        |> Pipeline.required "iat" Decode.int
        |> Pipeline.required "exp" Decode.int
        |> Pipeline.required "sub" Decode.string


decodeToken : String -> Result JwtError Payload
decodeToken token =
    Jwt.decodeToken payloadDecoder token
