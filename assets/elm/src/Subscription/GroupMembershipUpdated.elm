module Subscription.GroupMembershipUpdated exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipState
        , groupMembershipDecoder
        , groupMembershipStateDecoder
        )
import Socket exposing (Payload)


type alias Params =
    { groupId : String
    }


type alias Data =
    { groupId : String
    , membership : GroupMembership
    , state : GroupMembershipState
    }


clientId : String -> String
clientId id =
    "group_membership_updated_" ++ id


payload : String -> Payload
payload groupId =
    Payload (clientId groupId) query (Just <| variables <| Params groupId)


query : String
query =
    """
      subscription GroupMembershipUpdated(
        $groupId: ID!
      ) {
        groupMembershipUpdated(groupId: $groupId) {
          membership {
            state
            group {
              id
            }
            spaceUser {
              id
              firstName
              lastName
              role
            }
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "groupId", Encode.string params.groupId )
        ]


decoder : Decode.Decoder Data
decoder =
    Decode.at [ "data", "groupMembershipUpdated" ] <|
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "membership", "group", "id" ] Decode.string)
            |> Pipeline.custom (Decode.at [ "membership" ] groupMembershipDecoder)
            |> Pipeline.custom (Decode.at [ "membership", "state" ] groupMembershipStateDecoder)
        )
