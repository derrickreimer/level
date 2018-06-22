module Subscription.GroupUpdated exposing (..)

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


clientId : String -> String
clientId id =
    "group_updated_" ++ id


payload : String -> Payload
payload id =
    Payload (clientId id) query (Just <| variables <| Params id)


query : String
query =
    """
      subscription GroupUpdated(
        $id: ID!
      ) {
        groupUpdated(groupId: $id) {
          group {
            id
            name
            description
            isPrivate
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
    Decode.at [ "data", "groupUpdated" ] <|
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "group" ] groupDecoder)
        )
