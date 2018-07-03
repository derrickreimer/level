module Data.Group exposing (Group, fragment, groupDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
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


groupDecoder : Decode.Decoder Group
groupDecoder =
    Pipeline.decode Group
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string
