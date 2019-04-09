module Notification exposing
    ( Notification, Event(..), State(..)
    , id, occurredAt, event, state, topic, isUndismissed, setDismissed
    , fragment
    , decoder
    , withUndismissed, withState, withTopic
    )

{-| A Notification represents activity that occurred in someone's Inbox.


# Types

@docs Notification, Event, State


# API

@docs id, occurredAt, event, state, topic, isUndismissed, setDismissed


# GraphQL

@docs fragment


# Decoders

@docs decoder


# Filtering

@docs withUndismissed, withState, withTopic

-}

import Actor exposing (Actor, ActorId)
import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, list, maybe, string)
import Post exposing (Post)
import PostReaction exposing (PostReaction)
import Reply exposing (Reply)
import ReplyReaction exposing (ReplyReaction)
import SpaceUser exposing (SpaceUser)
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
    = PostCreated Id
    | PostClosed Id ActorId
    | PostReopened Id ActorId
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


occurredAt : Notification -> Posix
occurredAt (Notification data) =
    data.occurredAt


event : Notification -> Event
event (Notification data) =
    data.event


state : Notification -> State
state (Notification data) =
    data.state


topic : Notification -> String
topic (Notification data) =
    data.topic


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
                actor {
                  ...ActorFields
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
                actor {
                  ...ActorFields
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
                  spaceUser {
                    ...SpaceUserFields
                  }
                  post {
                    ...PostFields
                  }
                }
                occurredAt
              }
              ... on ReplyReactionCreatedNotification {
                id
                topic
                state
                reaction {
                  ...ReplyReactionFields
                  spaceUser {
                    ...SpaceUserFields
                  }
                  post {
                    ...PostFields
                  }
                  reply {
                    ...ReplyFields
                  }
                }
                occurredAt
              }
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Actor.fragment
        , Post.fragment
        , Reply.fragment
        , PostReaction.fragment
        , ReplyReaction.fragment
        , SpaceUser.fragment
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
                        field "post" (field "id" Id.decoder)

                "PostClosedNotification" ->
                    Decode.map2 PostClosed
                        (field "post" (field "id" Id.decoder))
                        (field "actor" Actor.idDecoder)

                "PostReopenedNotification" ->
                    Decode.map2 PostReopened
                        (field "post" (field "id" Id.decoder))
                        (field "actor" Actor.idDecoder)

                "ReplyCreatedNotification" ->
                    Decode.map ReplyCreated <|
                        field "reply" (field "id" Id.decoder)

                "PostReactionCreatedNotification" ->
                    -- It's possible the reaction will not decode properly
                    -- if the post does not exist. In that case, we'll
                    -- treat it the same as if the reaction itself had been
                    -- deleted.
                    Decode.map PostReactionCreated <|
                        field "reaction" PostReaction.decoder

                "ReplyReactionCreatedNotification" ->
                    -- It's possible the reaction will not decode properly
                    -- if the post does not exist. In that case, we'll
                    -- treat it the same as if the reaction itself had been
                    -- deleted.
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
withTopic testTopic (Notification data) =
    data.topic == testTopic
