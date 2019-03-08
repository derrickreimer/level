module Notification exposing
    ( Notification, Event(..), State(..)
    , id, occurredAt, event, state, isUndismissed, setDismissed
    , fragment
    , decoder
    , withUndismissed, withState, withTopic
    )

{-| A Notification represents activity that occurred in someone's Inbox.


# Types

@docs Notification, Event, State


# API

@docs id, occurredAt, event, state, isUndismissed, setDismissed


# GraphQL

@docs fragment


# Decoders

@docs decoder


# Filtering

@docs withUndismissed, withState, withTopic

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, list, maybe, string)
import Post exposing (Post)
import PostReaction exposing (PostReaction)
import Reply exposing (Reply)
import ReplyReaction exposing (ReplyReaction)
import Time exposing (Posix)
import Util exposing (dateDecoder)



-- TYPES


type Notification
    = Notification Data


type alias Data =
    { id : Id
    , topic : String
    , state : State
    , occurredAt : Posix
    , event : Event
    }


type Event
    = PostCreated (Maybe Id)
    | PostClosed (Maybe Id)
    | PostReopened (Maybe Id)
    | ReplyCreated (Maybe Id)
    | PostReactionCreated (Maybe PostReaction)
    | ReplyReactionCreated (Maybe ReplyReaction)


type State
    = Undismissed
    | Dismissed



-- API


id : Notification -> Id
id (Notification data) =
    data.id


occurredAt : Notification -> Posix
occurredAt (Notification data) =
    data.occurredAt


event : Notification -> Event
event (Notification data) =
    data.event


state : Notification -> State
state (Notification data) =
    data.state


isUndismissed : Notification -> Bool
isUndismissed (Notification data) =
    data.state == Undismissed


setDismissed : Notification -> Notification
setDismissed (Notification data) =
    Notification { data | state = Dismissed }



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
                occurredAt
              }
              ... on PostClosedNotification {
                id
                topic
                state
                post {
                  ...PostFields
                }
                occurredAt
              }
              ... on PostReopenedNotification {
                id
                topic
                state
                post {
                  ...PostFields
                }
                occurredAt
              }
              ... on ReplyCreatedNotification {
                id
                topic
                state
                reply {
                  ...ReplyFields
                }
                occurredAt
              }
              ... on PostReactionCreatedNotification {
                id
                topic
                state
                reaction {
                  ...PostReactionFields
                }
                occurredAt
              }
              ... on ReplyReactionCreatedNotification {
                id
                topic
                state
                reaction {
                  ...ReplyReactionFields
                }
                occurredAt
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
        Decode.map5 Data
            (field "id" Id.decoder)
            (field "topic" string)
            (field "state" stateDecoder)
            (field "occurredAt" dateDecoder)
            eventDecoder


eventDecoder : Decoder Event
eventDecoder =
    let
        decodeByTypename : String -> Decoder Event
        decodeByTypename typename =
            case typename of
                "PostCreatedNotification" ->
                    Decode.map PostCreated <|
                        field "post" (maybe (field "id" Id.decoder))

                "PostClosedNotification" ->
                    Decode.map PostClosed <|
                        field "post" (maybe (field "id" Id.decoder))

                "PostReopenedNotification" ->
                    Decode.map PostReopened <|
                        field "post" (maybe (field "id" Id.decoder))

                "ReplyCreatedNotification" ->
                    Decode.map ReplyCreated <|
                        field "reply" (maybe (field "id" Id.decoder))

                "PostReactionCreatedNotification" ->
                    -- It's possible the reaction will not decode properly
                    -- if the post does not exist. In that case, we'll
                    -- treat it the same as if the reaction itself had been
                    -- deleted.
                    Decode.map PostReactionCreated <|
                        Decode.oneOf
                            [ field "reaction" (maybe PostReaction.decoder)
                            , Decode.succeed Nothing
                            ]

                "ReplyReactionCreatedNotification" ->
                    -- It's possible the reaction will not decode properly
                    -- if the post does not exist. In that case, we'll
                    -- treat it the same as if the reaction itself had been
                    -- deleted.
                    Decode.map ReplyReactionCreated <|
                        Decode.oneOf
                            [ field "reaction" (maybe ReplyReaction.decoder)
                            , Decode.succeed Nothing
                            ]

                _ ->
                    Decode.fail "event not recognized"
    in
    Decode.field "__typename" string
        |> Decode.andThen decodeByTypename


stateDecoder : Decoder State
stateDecoder =
    let
        convert stateString =
            case stateString of
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


withState : State -> Notification -> Bool
withState testState (Notification data) =
    data.state == testState


withTopic : String -> Notification -> Bool
withTopic topic (Notification data) =
    data.topic == topic
