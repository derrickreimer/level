module Subscription.SpaceUserSubscription exposing (groupBookmarkedDecoder, groupUnbookmarkedDecoder, mentionsDismissedDecoder, postsDismissedDecoder, postsMarkedAsReadDecoder, postsMarkedAsUnreadDecoder, postsSubscribedDecoder, postsUnsubscribedDecoder, repliesViewedDecoder, subscribe, unsubscribe, userMentionedDecoder)

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


postsSubscribedDecoder : Decode.Decoder (List Post)
postsSubscribedDecoder =
    Subscription.decoder "spaceUser"
        "PostsSubscribed"
        "posts"
        (Decode.list Post.decoder)


postsUnsubscribedDecoder : Decode.Decoder (List Post)
postsUnsubscribedDecoder =
    Subscription.decoder "spaceUser"
        "PostsUnsubscribed"
        "posts"
        (Decode.list Post.decoder)


postsMarkedAsUnreadDecoder : Decode.Decoder (List Post)
postsMarkedAsUnreadDecoder =
    Subscription.decoder "spaceUser"
        "PostsMarkedAsUnread"
        "posts"
        (Decode.list Post.decoder)


postsMarkedAsReadDecoder : Decode.Decoder (List Post)
postsMarkedAsReadDecoder =
    Subscription.decoder "spaceUser"
        "PostsMarkedAsRead"
        "posts"
        (Decode.list Post.decoder)


postsDismissedDecoder : Decode.Decoder (List Post)
postsDismissedDecoder =
    Subscription.decoder "spaceUser"
        "PostsDismissed"
        "posts"
        (Decode.list Post.decoder)


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


repliesViewedDecoder : Decode.Decoder (List Reply)
repliesViewedDecoder =
    Subscription.decoder "spaceUser"
        "RepliesViewed"
        "replies"
        (Decode.list Reply.decoder)



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
            ... on PostsSubscribedPayload {
              posts {
                ...PostFields
              }
            }
            ... on PostsUnsubscribedPayload {
              posts {
                ...PostFields
              }
            }
            ... on PostsMarkedAsUnreadPayload {
              posts {
                ...PostFields
              }
            }
            ... on PostsMarkedAsReadPayload {
              posts {
                ...PostFields
              }
            }
            ... on PostsDismissedPayload {
              posts {
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
            ... on RepliesViewedPayload {
              replies {
                ...ReplyFields
              }
            }
          }
        }
        """
        [ Group.fragment
        , Post.fragment
        , Reply.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceUserId =
    Just <|
        Encode.object
            [ ( "spaceUserId", Encode.string spaceUserId )
            ]
