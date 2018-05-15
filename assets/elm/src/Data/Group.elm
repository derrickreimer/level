module Data.Group exposing (Group, groupDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


-- TYPES


type alias Group =
    { id : String
    , name : String
    }



-- DECODERS


groupDecoder : Decode.Decoder Group
groupDecoder =
    Pipeline.decode Group
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
