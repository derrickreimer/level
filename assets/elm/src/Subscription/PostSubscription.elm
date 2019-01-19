module Subscription.PostSubscription exposing (postClosedDecoder, postDeletedDecoder, postReactionCreatedDecoder, postReactionDeletedDecoder, postReopenedDecoder, postUpdatedDecoder, replyCreatedDecoder, replyDeletedDecoder, replyReactionCreatedDecoder, replyReactionDeletedDecoder, replyUpdatedDecoder, subscribe, unsubscribe)

import GraphQL exposing (Document)
import Json.Decode as Decode
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import Socket
import Subscription



-- SOCKETS


subscribe : String -> Cmd msg
subscribe postId =
    Subscription.send (clientId postId) document (variables postId)


unsubscribe : String -> Cmd msg
unsubscribe postId =
    Subscription.cancel (clientId postId)



-- DECODERS


postUpdatedDecoder : Decode.Decoder Post
postUpdatedDecoder =
    Subscription.decoder "post"
        "PostUpdated"
        "post"
        Post.decoder


replyCreatedDecoder : Decode.Decoder Reply
replyCreatedDecoder =
    Subscription.decoder "post"
        "ReplyCreated"
        "reply"
        Reply.decoder


replyUpdatedDecoder : Decode.Decoder Reply
replyUpdatedDecoder =
    Subscription.decoder "post"
        "ReplyUpdated"
        "reply"
        Reply.decoder


replyDeletedDecoder : Decode.Decoder Reply
replyDeletedDecoder =
    Subscription.decoder "post"
        "ReplyDeleted"
        "reply"
        Reply.decoder


postClosedDecoder : Decode.Decoder Post
postClosedDecoder =
    Subscription.decoder "post"
        "PostClosed"
        "post"
        Post.decoder


postReopenedDecoder : Decode.Decoder Post
postReopenedDecoder =
    Subscription.decoder "post"
        "PostReopened"
        "post"
        Post.decoder


postDeletedDecoder : Decode.Decoder Post
postDeletedDecoder =
    Subscription.decoder "post"
        "PostDeleted"
        "post"
        Post.decoder


postReactionCreatedDecoder : Decode.Decoder Post
postReactionCreatedDecoder =
    Subscription.decoder "post"
        "PostReactionCreated"
        "post"
        Post.decoder


postReactionDeletedDecoder : Decode.Decoder Post
postReactionDeletedDecoder =
    Subscription.decoder "post"
        "PostReactionDeleted"
        "post"
        Post.decoder


replyReactionCreatedDecoder : Decode.Decoder Reply
replyReactionCreatedDecoder =
    Subscription.decoder "post"
        "ReplyReactionCreated"
        "reply"
        Reply.decoder


replyReactionDeletedDecoder : Decode.Decoder Reply
replyReactionDeletedDecoder =
    Subscription.decoder "post"
        "ReplyReactionDeleted"
        "reply"
        Reply.decoder



-- INTERNAL


clientId : String -> String
clientId id =
    "post_subscription_" ++ id


document : Document
document =
    GraphQL.toDocument
        """
        subscription PostSubscription(
          $postId: ID!
        ) {
          postSubscription(postId: $postId) {
            __typename
            ... on PostUpdatedPayload {
              post {
                ...PostFields
              }
            }
            ... on ReplyCreatedPayload {
              reply {
                ...ReplyFields
              }
            }
            ... on ReplyUpdatedPayload {
              reply {
                ...ReplyFields
              }
            }
            ... on ReplyDeletedPayload {
              reply {
                ...ReplyFields
              }
            }
            ... on PostClosedPayload {
              post {
                ...PostFields
              }
            }
            ... on PostReopenedPayload {
              post {
                ...PostFields
              }
            }
            ... on PostDeletedPayload {
              post {
                ...PostFields
              }
            }
            ... on PostReactionCreatedPayload {
              post {
                ...PostFields
              }
            }
            ... on PostReactionDeletedPayload {
              post {
                ...PostFields
              }
            }
            ... on ReplyReactionCreatedPayload {
              reply {
                ...ReplyFields
              }
            }
            ... on ReplyReactionDeletedPayload {
              reply {
                ...ReplyFields
              }
            }
          }
        }
        """
        [ Post.fragment
        , Reply.fragment
        ]


variables : String -> Maybe Encode.Value
variables postId =
    Just <|
        Encode.object
            [ ( "postId", Encode.string postId )
            ]
