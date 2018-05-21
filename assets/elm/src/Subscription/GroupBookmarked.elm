module Subscription.GroupBookmarked exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Data.Group exposing (Group, groupDecoder)
import Socket exposing (Payload)


type alias Params =
    { id : String
    }


type alias Data =
    { group : Group
    }


payload : String -> Payload
payload id =
    Payload query (Just (variables (Params id)))


query : String
query =
    """
      subscription GroupBookmarked(
        $id: ID!
      ) {
        groupBookmarked(spaceUserId: $id) {
          group {
            id
            name
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "id", Encode.string params.id )
        ]


decoder : Decode.Decoder Data
decoder =
    Decode.at [ "data", "groupBookmarked" ] <|
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "group" ] groupDecoder)
        )
