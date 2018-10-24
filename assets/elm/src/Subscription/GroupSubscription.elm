module Subscription.GroupSubscription exposing (groupUpdatedDecoder, postCreatedDecoder, subscribe, subscribedToGroupDecoder, unsubscribe, unsubscribedFromGroupDecoder)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
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


postCreatedDecoder : Decode.Decoder ( Post, Connection Reply )
postCreatedDecoder =
    Subscription.decoder "group"
        "PostCreated"
        "post"
        Post.decoderWithReplies


subscribedToGroupDecoder : Decode.Decoder Group
subscribedToGroupDecoder =
    Subscription.decoder "group"
        "SubscribedToGroup"
        "group"
        Group.decoder


unsubscribedFromGroupDecoder : Decode.Decoder Group
unsubscribedFromGroupDecoder =
    Subscription.decoder "group"
        "UnsubscribedFromGroup"
        "group"
        Group.decoder



-- INTERNAL


clientId : String -> String
clientId id =
    "group_subscription_" ++ id


document : Document
document =
    GraphQL.toDocument
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
                replies(last: 5) {
                  ...ReplyConnectionFields
                }
              }
            }
            ... on SubscribedToGroupPayload {
              group {
                ...GroupFields
              }
            }
            ... on UnsubscribedFromGroupPayload {
              group {
                ...GroupFields
              }
            }
          }
        }
        """
        [ Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        , Group.fragment
        ]


variables : String -> Maybe Encode.Value
variables groupId =
    Just <|
        Encode.object
            [ ( "groupId", Encode.string groupId )
            ]
