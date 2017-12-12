module Data.PageInfo exposing (PageInfo, pageInfoDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


-- TYPES


type alias PageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    , startCursor : String
    , endCursor : String
    }



-- DECODERS


pageInfoDecoder : Decode.Decoder PageInfo
pageInfoDecoder =
    Pipeline.decode PageInfo
        |> Pipeline.required "hasPreviousPage" Decode.bool
        |> Pipeline.required "hasNextPage" Decode.bool
        |> Pipeline.required "startCursor" Decode.string
        |> Pipeline.required "endCursor" Decode.string
