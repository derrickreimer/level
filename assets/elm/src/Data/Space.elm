module Data.Space exposing (Space, fragment, decoder)

import Json.Decode as Decode exposing (field, string)
import GraphQL exposing (Fragment)


-- TYPES


type alias Space =
    { id : String
    , name : String
    , slug : String
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment SpaceFields on Space {
          id
          name
          slug
        }
        """
        []



-- DECODERS


decoder : Decode.Decoder Space
decoder =
    Decode.map3 Space
        (field "id" string)
        (field "name" string)
        (field "slug" string)
