module Data.ValidationError exposing (ValidationError, fragment, decoder, errorsFor, errorsNotFor)

import Json.Decode as Decode exposing (Decoder, field, string)
import GraphQL exposing (Fragment)


-- TYPES


type alias ValidationError =
    { attribute : String
    , message : String
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment ErrorFields on Error {
          attribute
          message
        }
        """
        []



-- DECODERS


decoder : Decoder ValidationError
decoder =
    Decode.map2 ValidationError
        (field "attribute" string)
        (field "message" string)



-- HELPERS


errorsFor : String -> List ValidationError -> List ValidationError
errorsFor attribute errors =
    List.filter (\error -> error.attribute == attribute) errors


errorsNotFor : String -> List ValidationError -> List ValidationError
errorsNotFor attribute errors =
    List.filter (\error -> not (error.attribute == attribute)) errors
