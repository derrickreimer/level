module Post exposing
    ( Post, Data, InboxState(..), State(..), SubscriptionState(..)
    , id, spaceId, fetchedAt, postedAt, author, groupIds, groupsInclude, state, body, bodyHtml, files, subscriptionState, inboxState, canEdit, hasReacted, reactionCount, reactorIds, isPrivate
    , fragment
    , decoder, decoderWithReplies
    )

{-| A post represents a message posted to group.


# Types

@docs Post, Data, InboxState, State, SubscriptionState


# Properties

@docs id, spaceId, fetchedAt, postedAt, author, groupIds, groupsInclude, state, body, bodyHtml, files, subscriptionState, inboxState, canEdit, hasReacted, reactionCount, reactorIds, isPrivate


# GraphQL

@docs fragment


# Decoders

@docs decoder, decoderWithReplies

-}

import Author exposing (Author)
import Connection exposing (Connection)
import File exposing (File)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, list, string, succeed)
import Json.Decode.Pipeline as Pipeline exposing (custom, required)
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
    | Deleted


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
    , spaceId : Id
    , state : State
    , body : String
    , bodyHtml : String
    , author : Author
    , groupIds : List Id
    , files : List File
    , postedAt : Posix
    , subscriptionState : SubscriptionState
    , inboxState : InboxState
    , canEdit : Bool
    , hasReacted : Bool
    , reactionCount : Int
    , reactorIds : List Id
    , isPrivate : Bool
    , fetchedAt : Int
    }



-- PROPERTIES


id : Post -> Id
id (Post data) =
    data.id


spaceId : Post -> Id
spaceId (Post data) =
    data.spaceId


fetchedAt : Post -> Int
fetchedAt (Post data) =
    data.fetchedAt


postedAt : Post -> Posix
postedAt (Post data) =
    data.postedAt


author : Post -> Author
author (Post data) =
    data.author


groupIds : Post -> List Id
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


files : Post -> List File
files (Post data) =
    data.files


subscriptionState : Post -> SubscriptionState
subscriptionState (Post data) =
    data.subscriptionState


inboxState : Post -> InboxState
inboxState (Post data) =
    data.inboxState


canEdit : Post -> Bool
canEdit (Post data) =
    data.canEdit


hasReacted : Post -> Bool
hasReacted (Post data) =
    data.hasReacted


reactionCount : Post -> Int
reactionCount (Post data) =
    data.reactionCount


reactorIds : Post -> List Id
reactorIds (Post data) =
    data.reactorIds


isPrivate : Post -> Bool
isPrivate (Post data) =
    data.isPrivate



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment PostFields on Post {
              id
              space {
                id
              }
              state
              body
              bodyHtml
              postedAt
              subscriptionState
              inboxState
              author {
                ...AuthorFields
              }
              groups {
                ...GroupFields
              }
              files {
                ...FileFields
              }
              reactions(first: 100) {
                edges {
                  node {
                    spaceUser {
                      ...SpaceUserFields
                    }
                  }
                }
                totalCount
              }
              canEdit
              hasReacted
              isPrivate
              fetchedAt
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Author.fragment
        , Group.fragment
        , File.fragment
        , SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder Post
decoder =
    Decode.map Post <|
        (Decode.succeed Data
            |> required "id" Id.decoder
            |> custom (Decode.at [ "space", "id" ] Id.decoder)
            |> required "state" stateDecoder
            |> required "body" string
            |> required "bodyHtml" string
            |> required "author" Author.decoder
            |> required "groups" (list (field "id" Id.decoder))
            |> required "files" (list File.decoder)
            |> required "postedAt" dateDecoder
            |> required "subscriptionState" subscriptionStateDecoder
            |> required "inboxState" inboxStateDecoder
            |> required "canEdit" bool
            |> required "hasReacted" bool
            |> custom (Decode.at [ "reactions", "totalCount" ] int)
            |> custom (Decode.at [ "reactions", "edges" ] (list <| Decode.at [ "node", "spaceUser", "id" ] Id.decoder))
            |> required "isPrivate" bool
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

                "DELETED" ->
                    succeed Deleted

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
