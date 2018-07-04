module Data.Group exposing (Group, fragment, decoder)

import Json.Decode as Decode exposing (Decoder, field, string)
import GraphQL exposing (Fragment)


-- TYPES


type alias Group =
    { id : String
    , name : String
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment GroupFields on Group {
          id
          name
        }
        """
        []



-- DECODERS


decoder : Decoder Group
decoder =
    Decode.map2 Group
        (field "id" string)
        (field "name" string)
