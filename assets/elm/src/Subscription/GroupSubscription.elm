module Subscription.GroupSubscription
    exposing
        ( subscribe
        , unsubscribe
        , groupUpdatedDecoder
        , postCreatedDecoder
        , groupMembershipUpdatedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Data.Group as Group exposing (Group)
import Data.Post as Post exposing (Post)
import GraphQL exposing (Document)
import Socket
import Subscription


-- SOCKETS


subscribe : String -> Cmd msg
subscribe groupId =
    Socket.send (clientId groupId) document (variables groupId)


unsubscribe : String -> Cmd msg
unsubscribe groupId =
    Socket.cancel (clientId groupId)



-- DECODERS


groupUpdatedDecoder : Decode.Decoder Group
groupUpdatedDecoder =
    Subscription.decoder "group"
        "GroupUpdated"
        "group"
        Group.decoder


postCreatedDecoder : Decode.Decoder Post
postCreatedDecoder =
    Subscription.decoder "group"
        "PostCreated"
        "post"
        Post.decoder


groupMembershipUpdatedDecoder : Decode.Decoder Group
groupMembershipUpdatedDecoder =
    Subscription.decoder "group"
        "GroupMembershipUpdated"
        "group"
        Group.decoder



-- INTERNAL


clientId : String -> String
clientId id =
    "group_subscription_" ++ id


document : Document
document =
    GraphQL.document
        """
        subscription GroupSubscription(
          $groupId: ID!
        ) {
          groupSubscription(groupId: $groupId) {
            __typename
            ... on GroupUpdatedPayload {
              group {
                ...GroupFields
              }
            }
            ... on PostCreatedPayload {
              post {
                ...PostFields
              }
            }
            ... on GroupMembershipUpdatedPayload {
              group {
                ...GroupFields
              }
            }
          }
        }
        """
        [ Post.fragment 5
        , Group.fragment
        ]


variables : String -> Maybe Encode.Value
variables groupId =
    Just <|
        Encode.object
            [ ( "groupId", Encode.string groupId )
            ]
