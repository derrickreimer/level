module Post exposing
    ( Post, Data, InboxState(..), State(..), SubscriptionState(..)
    , id, fetchedAt, postedAt, authorId, groupIds, groupsInclude, state, body, bodyHtml, subscriptionState, inboxState, canEdit
    , fragment
    , decoder, decoderWithReplies
    )

{-| A post represents a message posted to group.


# Types

@docs Post, Data, InboxState, State, SubscriptionState


# Properties

@docs id, fetchedAt, postedAt, authorId, groupIds, groupsInclude, state, body, bodyHtml, subscriptionState, inboxState, canEdit


# GraphQL

@docs fragment


# Decoders

@docs decoder, decoderWithReplies

-}

import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, list, string, succeed)
import Json.Decode.Pipeline as Pipeline exposing (required)
import List
import Reply exposing (Reply)
import SpaceUser exposing (SpaceUser)
import Time exposing (Posix)
import Util exposing (dateDecoder)



-- TYPES


type Post
    = Post Data


type State
    = Open
    | Closed


type SubscriptionState
    = NotSubscribed
    | Subscribed
    | Unsubscribed


type InboxState
    = Excluded
    | Dismissed
    | Read
    | Unread


type alias Data =
    { id : Id
    , state : State
    , body : String
    , bodyHtml : String
    , authorId : String
    , groupIds : List String
    , postedAt : Posix
    , subscriptionState : SubscriptionState
    , inboxState : InboxState
    , canEdit : Bool
    , fetchedAt : Int
    }



-- PROPERTIES


id : Post -> Id
id (Post data) =
    data.id


fetchedAt : Post -> Int
fetchedAt (Post data) =
    data.fetchedAt


postedAt : Post -> Posix
postedAt (Post data) =
    data.postedAt


authorId : Post -> String
authorId (Post data) =
    data.authorId


groupIds : Post -> List String
groupIds (Post data) =
    data.groupIds


groupsInclude : Group -> Post -> Bool
groupsInclude group (Post data) =
    List.filter (\gid -> gid == Group.id group) data.groupIds
        |> List.isEmpty
        |> not


state : Post -> State
state (Post data) =
    data.state


body : Post -> String
body (Post data) =
    data.body


bodyHtml : Post -> String
bodyHtml (Post data) =
    data.bodyHtml


subscriptionState : Post -> SubscriptionState
subscriptionState (Post data) =
    data.subscriptionState


inboxState : Post -> InboxState
inboxState (Post data) =
    data.inboxState


canEdit : Post -> Bool
canEdit (Post data) =
    data.canEdit



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment PostFields on Post {
              id
              state
              body
              bodyHtml
              postedAt
              subscriptionState
              inboxState
              author {
                ...SpaceUserFields
              }
              groups {
                ...GroupFields
              }
              canEdit
              fetchedAt
            }
            """
    in
    GraphQL.toFragment queryBody
        [ SpaceUser.fragment
        , Group.fragment
        ]



-- DECODERS


decoder : Decoder Post
decoder =
    Decode.map Post <|
        (Decode.succeed Data
            |> required "id" Id.decoder
            |> required "state" stateDecoder
            |> required "body" string
            |> required "bodyHtml" string
            |> required "author" (field "id" Id.decoder)
            |> required "groups" (list (field "id" Id.decoder))
            |> required "postedAt" dateDecoder
            |> required "subscriptionState" subscriptionStateDecoder
            |> required "inboxState" inboxStateDecoder
            |> required "canEdit" bool
            |> required "fetchedAt" int
        )


decoderWithReplies : Decoder ( Post, Connection Reply )
decoderWithReplies =
    Decode.map2 Tuple.pair decoder (field "replies" (Connection.decoder Reply.decoder))


stateDecoder : Decoder State
stateDecoder =
    let
        convert : String -> Decoder State
        convert raw =
            case raw of
                "OPEN" ->
                    succeed Open

                "CLOSED" ->
                    succeed Closed

                _ ->
                    fail "State not valid"
    in
    Decode.andThen convert string


subscriptionStateDecoder : Decoder SubscriptionState
subscriptionStateDecoder =
    let
        convert : String -> Decoder SubscriptionState
        convert raw =
            case raw of
                "SUBSCRIBED" ->
                    succeed Subscribed

                "UNSUBSCRIBED" ->
                    succeed Unsubscribed

                "NOT_SUBSCRIBED" ->
                    succeed NotSubscribed

                _ ->
                    fail "Subscription state not valid"
    in
    Decode.andThen convert string


inboxStateDecoder : Decoder InboxState
inboxStateDecoder =
    let
        convert : String -> Decoder InboxState
        convert raw =
            case raw of
                "EXCLUDED" ->
                    succeed Excluded

                "DISMISSED" ->
                    succeed Dismissed

                "READ" ->
                    succeed Read

                "UNREAD" ->
                    succeed Unread

                _ ->
                    fail "Inbox state not valid"
    in
    Decode.andThen convert string
