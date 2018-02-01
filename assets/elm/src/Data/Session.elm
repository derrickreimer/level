module Data.Session exposing (Session, Payload, payloadDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


-- TYPES


type alias Payload =
    { iat : Int
    , exp : Int
    , sub : String
    }


type alias Session =
    { token : String
    }


payloadDecoder : Decode.Decoder Payload
payloadDecoder =
    Pipeline.decode Payload
        |> Pipeline.required "iat" Decode.int
        |> Pipeline.required "exp" Decode.int
        |> Pipeline.required "sub" Decode.string
