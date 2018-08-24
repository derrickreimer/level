module Subscription.SpaceUserSubscription exposing (groupBookmarkedDecoder, groupUnbookmarkedDecoder, mentionsDismissedDecoder, postSubscribedDecoder, postUnsubscribedDecoder, subscribe, unsubscribe, userMentionedDecoder)

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
        "GroupUnbookmarked"
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


userMentionedDecoder : Decode.Decoder Post
userMentionedDecoder =
    Subscription.decoder "spaceUser"
        "UserMentioned"
        "post"
        Post.decoder


mentionsDismissedDecoder : Decode.Decoder Post
mentionsDismissedDecoder =
    Subscription.decoder "spaceUser"
        "MentionsDismissed"
        "post"
        Post.decoder



-- INTERNAL


clientId : String -> String
clientId spaceUserId =
    "space_user_subscription_" ++ spaceUserId


document : Document
document =
    GraphQL.toDocument
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
              }
            }
            ... on PostUnsubscribedPayload {
              post {
                ...PostFields
              }
            }
            ... on UserMentionedPayload {
              post {
                ...PostFields
              }
            }
            ... on MentionsDismissedPayload {
              post {
                ...PostFields
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
