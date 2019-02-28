module Notification exposing
    ( Notification, Event(..)
    , fragment
    , decoder
    )

{-| A Notification represents activity that occurred in someone's Inbox.


# Types

@docs Notification, Event


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, list, string)
import Post exposing (Post)
import Reply exposing (Reply)



-- TYPES


type Notification
    = Notification Data


type alias Data =
    { id : Id
    , topic : String
    , event : Event
    }


type Event
    = PostCreated Id
    | PostClosed Id
    | PostReopened Id
    | ReplyCreated Id
    | PostReactionCreated Id
    | ReplyReactionCreated Id



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment NotificationFields on Notification {
              __typename
              ... on PostCreatedNotification {
                id
                topic
                post {
                  ...PostFields
                }
              }
              ... on PostClosedNotification {
                id
                topic
                post {
                  ...PostFields
                }
              }
              ... on PostReopenedNotification {
                id
                topic
                post {
                  ...PostFields
                }
              }
              ... on ReplyCreatedNotification {
                id
                topic
                reply {
                  ...ReplyFields
                }
              }
              ... on PostReactionCreatedNotification {
                id
                topic
                post {
                  ...PostFields
                }
              }
              ... on ReplyReactionCreatedNotification {
                id
                topic
                reply {
                  ...ReplyFields
                }
              }
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Post.fragment
        , Reply.fragment
        ]



-- DECODERS


decoder : Decoder Notification
decoder =
    Decode.map Notification <|
        Decode.map3 Data
            (field "id" Id.decoder)
            (field "topic" string)
            eventDecoder


eventDecoder : Decoder Event
eventDecoder =
    let
        decodeByTypename : String -> Decoder Event
        decodeByTypename typename =
            case typename of
                "POST_CREATED" ->
                    Decode.map PostCreated <|
                        Decode.at [ "post", "id" ] Id.decoder

                "POST_CLOSED" ->
                    Decode.map PostClosed <|
                        Decode.at [ "post", "id" ] Id.decoder

                "POST_REOPENED" ->
                    Decode.map PostReopened <|
                        Decode.at [ "post", "id" ] Id.decoder

                "REPLY_CREATED" ->
                    Decode.map ReplyCreated <|
                        Decode.at [ "reply", "id" ] Id.decoder

                "POST_REACTION_CREATED" ->
                    Decode.map PostReactionCreated <|
                        Decode.at [ "post", "id" ] Id.decoder

                "REPLY_REACTION_CREATED" ->
                    Decode.map ReplyReactionCreated <|
                        Decode.at [ "reply", "id" ] Id.decoder

                _ ->
                    Decode.fail "event not recognized"
    in
    Decode.field "__typename" string
        |> Decode.andThen decodeByTypename
