module Data.ValidationError exposing (..)

import Json.Decode as Decode


type alias ValidationError =
    { attribute : String
    , message : String
    }


errorsFor : String -> List ValidationError -> List ValidationError
errorsFor attribute errors =
    List.filter (\error -> error.attribute == attribute) errors


errorsNotFor : String -> List ValidationError -> List ValidationError
errorsNotFor attribute errors =
    List.filter (\error -> not (error.attribute == attribute)) errors


errorDecoder : Decode.Decoder ValidationError
errorDecoder =
    Decode.map2 ValidationError
        (Decode.field "attribute" Decode.string)
        (Decode.field "message" Decode.string)
