module Subscription.SpaceUserSubscription exposing (groupBookmarkedDecoder, groupUnbookmarkedDecoder, mentionsDismissedDecoder, postCreatedDecoder, postsDismissedDecoder, postsMarkedAsReadDecoder, postsMarkedAsUnreadDecoder, postsSubscribedDecoder, postsUnsubscribedDecoder, repliesViewedDecoder, subscribe, unsubscribe, userMentionedDecoder)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Socket
import Subscription



-- SOCKETS


subscribe : String -> Cmd msg
subscribe spaceUserId =
    Subscription.send (clientId spaceUserId) document (variables spaceUserId)


unsubscribe : String -> Cmd msg
unsubscribe spaceUserId =
    Subscription.cancel (clientId spaceUserId)



-- DECODERS


postCreatedDecoder : Decode.Decoder ResolvedPostWithReplies
postCreatedDecoder =
    Subscription.decoder "spaceUser"
        "PostCreated"
        "post"
        ResolvedPostWithReplies.decoder


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


postsMarkedAsUnreadDecoder : Decode.Decoder (List ResolvedPostWithReplies)
postsMarkedAsUnreadDecoder =
    Subscription.decoder "spaceUser"
        "PostsMarkedAsUnread"
        "posts"
        (Decode.list ResolvedPostWithReplies.decoder)


postsMarkedAsReadDecoder : Decode.Decoder (List ResolvedPostWithReplies)
postsMarkedAsReadDecoder =
    Subscription.decoder "spaceUser"
        "PostsMarkedAsRead"
        "posts"
        (Decode.list ResolvedPostWithReplies.decoder)


postsDismissedDecoder : Decode.Decoder (List ResolvedPostWithReplies)
postsDismissedDecoder =
    Subscription.decoder "spaceUser"
        "PostsDismissed"
        "posts"
        (Decode.list ResolvedPostWithReplies.decoder)


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
            ... on PostCreatedPayload {
              post {
                ...PostFields
                replies(last: 5) {
                  ...ReplyConnectionFields
                }
              }
            }
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
                replies(last: 3) {
                  ...ReplyConnectionFields
                }
              }
            }
            ... on PostsMarkedAsReadPayload {
              posts {
                ...PostFields
                replies(last: 3) {
                  ...ReplyConnectionFields
                }
              }
            }
            ... on PostsDismissedPayload {
              posts {
                ...PostFields
                replies(last: 3) {
                  ...ReplyConnectionFields
                }
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
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceUserId =
    Just <|
        Encode.object
            [ ( "spaceUserId", Encode.string spaceUserId )
            ]
