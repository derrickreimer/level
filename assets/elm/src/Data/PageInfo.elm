module Data.PageInfo exposing (PageInfo, fragment, decoder)

import Json.Decode as Decode exposing (Decoder, field, bool, maybe, string)
import GraphQL exposing (Fragment)


-- TYPES


type alias PageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    , startCursor : Maybe String
    , endCursor : Maybe String
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment PageInfoFields on PageInfo {
          hasPreviousPage
          hasNextPage
          startCursor
          endCursor
        }
        """
        []



-- DECODERS


decoder : Decoder PageInfo
decoder =
    Decode.map4 PageInfo
        (field "hasPreviousPage" bool)
        (field "hasNextPage" bool)
        (field "startCursor" (maybe string))
        (field "endCursor" (maybe string))
