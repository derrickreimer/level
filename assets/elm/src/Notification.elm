module Notification exposing
    ( Notification, Event(..)
    , id, event
    , fragment
    , decoder
    , withUndismissed
    )

{-| A Notification represents activity that occurred in someone's Inbox.


# Types

@docs Notification, Event


# API

@docs id, event


# GraphQL

@docs fragment


# Decoders

@docs decoder


# Filtering

@docs withUndismissed

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, list, string)
import Post exposing (Post)
import PostReaction exposing (PostReaction)
import Reply exposing (Reply)
import ReplyReaction exposing (ReplyReaction)



-- TYPES


type Notification
    = Notification Data


type alias Data =
    { id : Id
    , topic : String
    , state : State
    , event : Event
    }


type Event
    = PostCreated Id
    | PostClosed Id
    | PostReopened Id
    | ReplyCreated Id
    | PostReactionCreated PostReaction
    | ReplyReactionCreated ReplyReaction


type State
    = Undismissed
    | Dismissed



-- API


id : Notification -> Id
id (Notification data) =
    data.id


event : Notification -> Event
event (Notification data) =
    data.event



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
                state
                post {
                  ...PostFields
                }
              }
              ... on PostClosedNotification {
                id
                topic
                state
                post {
                  ...PostFields
                }
              }
              ... on PostReopenedNotification {
                id
                topic
                state
                post {
                  ...PostFields
                }
              }
              ... on ReplyCreatedNotification {
                id
                topic
                state
                reply {
                  ...ReplyFields
                }
              }
              ... on PostReactionCreatedNotification {
                id
                topic
                state
                reaction {
                  ...PostReactionFields
                }
              }
              ... on ReplyReactionCreatedNotification {
                id
                topic
                state
                reaction {
                  ...ReplyReactionFields
                }
              }
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Post.fragment
        , Reply.fragment
        , PostReaction.fragment
        , ReplyReaction.fragment
        ]



-- DECODERS


decoder : Decoder Notification
decoder =
    Decode.map Notification <|
        Decode.map4 Data
            (field "id" Id.decoder)
            (field "topic" string)
            (field "state" stateDecoder)
            eventDecoder


eventDecoder : Decoder Event
eventDecoder =
    let
        decodeByTypename : String -> Decoder Event
        decodeByTypename typename =
            case typename of
                "PostCreatedNotification" ->
                    Decode.map PostCreated <|
                        Decode.at [ "post", "id" ] Id.decoder

                "PostClosedNotification" ->
                    Decode.map PostClosed <|
                        Decode.at [ "post", "id" ] Id.decoder

                "PostReopenedNotification" ->
                    Decode.map PostReopened <|
                        Decode.at [ "post", "id" ] Id.decoder

                "ReplyCreatedNotification" ->
                    Decode.map ReplyCreated <|
                        Decode.at [ "reply", "id" ] Id.decoder

                "PostReactionCreatedNotification" ->
                    Decode.map PostReactionCreated <|
                        field "reaction" PostReaction.decoder

                "ReplyReactionCreatedNotification" ->
                    Decode.map ReplyReactionCreated <|
                        field "reaction" ReplyReaction.decoder

                _ ->
                    Decode.fail "event not recognized"
    in
    Decode.field "__typename" string
        |> Decode.andThen decodeByTypename


stateDecoder : Decoder State
stateDecoder =
    let
        convert state =
            case state of
                "UNDISMISSED" ->
                    Decode.succeed Undismissed

                "DISMISSED" ->
                    Decode.succeed Dismissed

                _ ->
                    Decode.fail "notification state not recognized"
    in
    string
        |> Decode.andThen convert



-- FILTERING


withUndismissed : Notification -> Bool
withUndismissed (Notification data) =
    data.state == Undismissed
