module Subscription.SpaceUserSubscription
    exposing
        ( subscribe
        , unsubscribe
        , groupBookmarkedDecoder
        , groupUnbookmarkedDecoder
        , postSubscribedDecoder
        , postUnsubscribedDecoder
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import GraphQL exposing (Document)
import Socket
import Subscription


-- SOCKETS


subscribe : String -> Cmd msg
subscribe spaceUserId =
    Socket.send (clientId spaceUserId) document (variables spaceUserId)


unsubscribe : String -> Cmd msg
unsubscribe spaceUserId =
    Socket.cancel (clientId spaceUserId)



-- DECODERS


groupBookmarkedDecoder : Decode.Decoder Group
groupBookmarkedDecoder =
    Subscription.decoder "spaceUser"
        "GroupBookmarked"
        "group"
        Group.decoder


groupUnbookmarkedDecoder : Decode.Decoder Group
groupUnbookmarkedDecoder =
    Subscription.decoder "spaceUser"
        "GroupUnookmarked"
        "group"
        Group.decoder


postSubscribedDecoder : Decode.Decoder Post
postSubscribedDecoder =
    Subscription.decoder "spaceUser"
        "PostSubscribed"
        "post"
        Post.decoder


postUnsubscribedDecoder : Decode.Decoder Post
postUnsubscribedDecoder =
    Subscription.decoder "spaceUser"
        "PostUnsubscribed"
        "post"
        Post.decoder



-- INTERNAL


clientId : String -> String
clientId spaceUserId =
    "space_user_subscription_" ++ spaceUserId


document : Document
document =
    GraphQL.document
        """
        subscription SpaceUserSubscription(
          $spaceUserId: ID!
        ) {
          spaceUserSubscription(spaceUserId: $spaceUserId) {
            __typename
            ... on GroupBookmarkedPayload {
              group {
                ...GroupFields
              }
            }
            ... on GroupUnbookmarkedPayload {
              group {
                ...GroupFields
              }
            }
            ... on PostSubscribedPayload {
              post {
                ...PostFields
                replies(first: 5) {
                  ...ReplyConnectionFields
                }
              }
            }
            ... on PostUnsubscribedPayload {
              post {
                ...PostFields
                replies(first: 5) {
                  ...ReplyConnectionFields
                }
              }
            }
          }
        }
        """
        [ Group.fragment
        , Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceUserId =
    Just <|
        Encode.object
            [ ( "spaceUserId", Encode.string spaceUserId )
            ]
