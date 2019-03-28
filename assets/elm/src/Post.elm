module Post exposing
    ( Post, Data, InboxState(..), State(..), SubscriptionState(..)
    , id, spaceId, fetchedAt, postedAt, author, groupIds, groupsInclude, recipientIds, state, body, bodyHtml, files, url, subscriptionState, inboxState, canEdit, hasReacted, reactionCount, reactorIds, isPrivate, isUrgent, isInGroup
    , setInboxState
    , fragment
    , decoder, decoderWithReplies
    , asc, desc
    , withSpace, withGroup, withInboxState, withAnyGroups, withFollowing, withAuthor, withRecipients
    )

{-| A post represents a message posted to group.


# Types

@docs Post, Data, InboxState, State, SubscriptionState


# Properties

@docs id, spaceId, fetchedAt, postedAt, author, groupIds, groupsInclude, recipientIds, state, body, bodyHtml, files, url, subscriptionState, inboxState, canEdit, hasReacted, reactionCount, reactorIds, isPrivate, isUrgent, isInGroup


# Mutations

@docs setInboxState


# GraphQL

@docs fragment


# Decoders

@docs decoder, decoderWithReplies


# Sorting

@docs asc, desc


# Filtering

@docs withSpace, withGroup, withInboxState, withAnyGroups, withFollowing, withAuthor, withRecipients

-}

import Actor exposing (Actor)
import Author exposing (Author)
import Connection exposing (Connection)
import File exposing (File)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Id exposing (Id)
import InboxStateFilter exposing (InboxStateFilter)
import Json.Decode as Decode exposing (Decoder, bool, fail, field, int, list, string, succeed)
import Json.Decode.Pipeline as Pipeline exposing (custom, required)
import List
import PostReaction exposing (PostReaction)
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
    , recipientIds : List Id
    , files : List File
    , postedAt : Posix
    , subscriptionState : SubscriptionState
    , inboxState : InboxState
    , canEdit : Bool
    , hasReacted : Bool
    , reactionCount : Int
    , reactorIds : List Id
    , url : String
    , isPrivate : Bool
    , isUrgent : Bool
    , lastActivityAt : Posix
    , fetchedAt : Posix
    }



-- PROPERTIES


id : Post -> Id
id (Post data) =
    data.id


spaceId : Post -> Id
spaceId (Post data) =
    data.spaceId


fetchedAt : Post -> Posix
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


recipientIds : Post -> List Id
recipientIds (Post data) =
    data.recipientIds


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


url : Post -> String
url (Post data) =
    data.url


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


isUrgent : Post -> Bool
isUrgent (Post data) =
    data.isUrgent


isInGroup : Id -> Post -> Bool
isInGroup groupId (Post data) =
    List.member groupId data.groupIds



-- MUTATIONS


setInboxState : InboxState -> Post -> Post
setInboxState newState (Post data) =
    Post { data | inboxState = newState }



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
              recipients {
                ...SpaceUserFields
              }
              files {
                ...FileFields
              }
              reactions(first: 100) {
                edges {
                  node {
                    ...PostReactionFields
                  }
                }
                totalCount
              }
              url
              canEdit
              hasReacted
              isPrivate
              isUrgent
              lastActivityAt
              fetchedAt
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Author.fragment
        , Group.fragment
        , File.fragment
        , SpaceUser.fragment
        , PostReaction.fragment
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
            |> required "recipients" (list (field "id" Id.decoder))
            |> required "files" (list File.decoder)
            |> required "postedAt" dateDecoder
            |> required "subscriptionState" subscriptionStateDecoder
            |> required "inboxState" inboxStateDecoder
            |> required "canEdit" bool
            |> required "hasReacted" bool
            |> custom (Decode.at [ "reactions", "totalCount" ] int)
            |> custom (Decode.at [ "reactions", "edges" ] (list <| Decode.at [ "node", "spaceUser", "id" ] Id.decoder))
            |> required "url" string
            |> required "isPrivate" bool
            |> required "isUrgent" bool
            |> required "lastActivityAt" dateDecoder
            |> required "fetchedAt" dateDecoder
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



-- SORTING


asc : Post -> Post -> Order
asc (Post a) (Post b) =
    compare (Time.posixToMillis a.postedAt) (Time.posixToMillis b.postedAt)


desc : Post -> Post -> Order
desc (Post a) (Post b) =
    let
        ac =
            Time.posixToMillis a.postedAt

        bc =
            Time.posixToMillis b.postedAt
    in
    case compare ac bc of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT



-- FILTERING


withSpace : Id -> Post -> Bool
withSpace matchingId post =
    spaceId post == matchingId


withGroup : Id -> Post -> Bool
withGroup matchingId post =
    List.member matchingId (groupIds post)


withInboxState : InboxStateFilter -> Post -> Bool
withInboxState filter (Post data) =
    case filter of
        InboxStateFilter.Undismissed ->
            data.inboxState == Read || data.inboxState == Unread

        InboxStateFilter.Dismissed ->
            data.inboxState == Dismissed

        InboxStateFilter.Unread ->
            data.inboxState == Unread

        _ ->
            True


withAnyGroups : List Id -> Post -> Bool
withAnyGroups matchingIds post =
    List.any (\testId -> List.member testId matchingIds) (groupIds post)


withFollowing : List Id -> Post -> Bool
withFollowing subscribedGroupIds post =
    isPrivate post
        || inboxState post
        /= Excluded
        || subscriptionState post
        == Subscribed
        || withAnyGroups subscribedGroupIds post


withAuthor : Maybe Actor -> Post -> Bool
withAuthor maybeActor post =
    case maybeActor of
        Just actor ->
            Author.actorId (author post) == Actor.id actor

        Nothing ->
            True


withRecipients : Maybe (List Id) -> Post -> Bool
withRecipients maybeMatchingIds post =
    case maybeMatchingIds of
        Just matchingIds ->
            List.sort matchingIds == List.sort (recipientIds post) && List.isEmpty (groupIds post)

        Nothing ->
            True
