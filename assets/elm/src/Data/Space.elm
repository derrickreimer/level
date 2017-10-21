module Data.Space exposing (Space, spaceDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


-- TYPES


type alias Space =
    { id : String
    , name : String
    }



-- DECODERS


spaceDecoder : Decode.Decoder Space
spaceDecoder =
    Pipeline.decode Space
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
