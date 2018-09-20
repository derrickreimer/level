module Post exposing
    ( Post
    , id, fetchedAt, postedAt, authorId, groupIds, groupsInclude
    , state, body, bodyHtml, subscriptionState, inboxState
    , update, updateMany
    , fragment
    , decoder, decoderWithReplies
    )

{-| A post represents a message posted to group.


# Types

@docs Post


# Immutable Properties

@docs id, fetchedAt, postedAt, authorId, groupIds, groupsInclude


# Mutable Properties

@docs state, body, bodyHtml, subscriptionState, inboxState


# Mutations

@docs update, updateMany


# GraphQL

@docs fragment


# Decoders

@docs decoder, decoderWithReplies

-}

import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field)
import List
import Mention exposing (Mention)
import Post.Types exposing (Data, InboxState, State, SubscriptionState)
import Reply exposing (Reply)
import Repo exposing (Repo)
import SpaceUser exposing (SpaceUser)
import Time exposing (Posix)



-- TYPES


type Post
    = Post Data



-- IMMUTABLE PROPERTIES


id : Post -> String
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



-- MUTABLE PROPERTIES


state : Repo -> Post -> State
state repo (Post data) =
    data.state


body : Repo -> Post -> String
body repo (Post data) =
    data.body


bodyHtml : Post -> String
bodyHtml (Post data) =
    data.bodyHtml


subscriptionState : Repo -> Post -> SubscriptionState
subscriptionState repo (Post data) =
    data.subscriptionState


inboxState : Repo -> Post -> InboxState
inboxState repo (Post data) =
    data.inboxState



-- MUTATIONS


update : Repo -> Post -> Repo
update repo (Post data) =
    Repo.setPost repo data


updateMany : Repo -> List Post -> Repo
updateMany repo posts =
    List.foldr (\post acc -> update acc post) repo posts



-- GRAPHQL


fragment : Fragment
fragment =
    Post.Types.fragment



-- DECODERS


decoder : Decoder Post
decoder =
    Decode.map Post Post.Types.decoder


decoderWithReplies : Decoder ( Post, Connection Reply )
decoderWithReplies =
    Decode.map2 Tuple.pair decoder (field "replies" (Connection.decoder Reply.decoder))
