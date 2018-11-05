module Repo exposing
    ( Repo
    , empty, union
    , getUser, setUser
    , getSpace, getSpaces, setSpace, setSpaces
    , getSpaceUser, getSpaceUsers, getSpaceUserByUserId, getSpaceUsersByUserId, setSpaceUser, setSpaceUsers
    , getSpaceBot, setSpaceBot
    , getActor, setActor
    , getGroup, getGroups, setGroup, setGroups
    , getPost, getPosts, setPost, setPosts
    , getReply, getReplies, setReply, setReplies
    )

{-| The repo is a central repository of data fetched from the server.


# Types

@docs Repo


# Operations

@docs empty, union


# Users

@docs getUser, setUser


# Spaces

@docs getSpace, getSpaces, setSpace, setSpaces


# Space Users

@docs getSpaceUser, getSpaceUsers, getSpaceUserByUserId, getSpaceUsersByUserId, filterSpaceUsers, setSpaceUser, setSpaceUsers


# Space Bots

@docs getSpaceBot, setSpaceBot


# Actors

@docs getActor, setActor


# Groups

@docs getGroup, getGroups, setGroup, setGroups


# Posts

@docs getPost, getPosts, setPost, setPosts


# Replies

@docs getReply, getReplies, setReply, setReplies

-}

import Actor exposing (Actor, ActorId)
import Dict exposing (Dict)
import Group exposing (Group)
import Id exposing (Id)
import Post exposing (Post)
import Reply exposing (Reply)
import Space exposing (Space)
import SpaceBot exposing (SpaceBot)
import SpaceUser exposing (SpaceUser)
import User exposing (User)


type Repo
    = Repo InternalData


type alias InternalData =
    { users : Dict Id User
    , spaces : Dict Id Space
    , spaceUsers : Dict Id SpaceUser
    , spaceBots : Dict Id SpaceBot
    , groups : Dict Id Group
    , posts : Dict Id Post
    , replies : Dict Id Reply
    }



-- OPERATIONS


empty : Repo
empty =
    Repo (InternalData Dict.empty Dict.empty Dict.empty Dict.empty Dict.empty Dict.empty Dict.empty)


union : Repo -> Repo -> Repo
union (Repo newer) (Repo older) =
    Repo <|
        InternalData
            (Dict.union newer.users older.users)
            (Dict.union newer.spaces older.spaces)
            (Dict.union newer.spaceUsers older.spaceUsers)
            (Dict.union newer.spaceBots older.spaceBots)
            (Dict.union newer.groups older.groups)
            (Dict.union newer.posts older.posts)
            (Dict.union newer.replies older.replies)



-- USERS


getUser : String -> Repo -> Maybe User
getUser id (Repo data) =
    Dict.get id data.users


setUser : User -> Repo -> Repo
setUser user (Repo data) =
    Repo { data | users = Dict.insert (User.id user) user data.users }



-- SPACES


getSpace : String -> Repo -> Maybe Space
getSpace id (Repo data) =
    Dict.get id data.spaces


getSpaces : List String -> Repo -> List Space
getSpaces ids repo =
    List.filterMap (\id -> getSpace id repo) ids


setSpace : Space -> Repo -> Repo
setSpace space (Repo data) =
    Repo { data | spaces = Dict.insert (Space.id space) space data.spaces }


setSpaces : List Space -> Repo -> Repo
setSpaces spaces repo =
    List.foldr setSpace repo spaces



-- SPACE USERS


getSpaceUser : String -> Repo -> Maybe SpaceUser
getSpaceUser id (Repo data) =
    Dict.get id data.spaceUsers


getSpaceUsers : List String -> Repo -> List SpaceUser
getSpaceUsers ids repo =
    List.filterMap (\id -> getSpaceUser id repo) ids


getSpaceUserByUserId : String -> Repo -> Maybe SpaceUser
getSpaceUserByUserId userId (Repo data) =
    data.spaceUsers
        |> Dict.values
        |> List.filter (\su -> SpaceUser.userId su == userId)
        |> List.head


getSpaceUsersByUserId : List String -> Repo -> List SpaceUser
getSpaceUsersByUserId userIds (Repo data) =
    data.spaceUsers
        |> Dict.values
        |> List.filter (\su -> List.member (SpaceUser.userId su) userIds)


setSpaceUser : SpaceUser -> Repo -> Repo
setSpaceUser spaceUser (Repo data) =
    Repo { data | spaceUsers = Dict.insert (SpaceUser.id spaceUser) spaceUser data.spaceUsers }


setSpaceUsers : List SpaceUser -> Repo -> Repo
setSpaceUsers spaceUsers repo =
    List.foldr setSpaceUser repo spaceUsers



-- SPACE BOTS


getSpaceBot : String -> Repo -> Maybe SpaceBot
getSpaceBot id (Repo data) =
    Dict.get id data.spaceBots


setSpaceBot : SpaceBot -> Repo -> Repo
setSpaceBot spaceBot (Repo data) =
    Repo { data | spaceBots = Dict.insert (SpaceBot.id spaceBot) spaceBot data.spaceBots }



-- SPACE BOTS


getActor : ActorId -> Repo -> Maybe Actor
getActor actorId repo =
    case actorId of
        Actor.UserId id ->
            Maybe.map Actor.User <|
                getSpaceUser id repo

        Actor.BotId id ->
            Maybe.map Actor.Bot <|
                getSpaceBot id repo


setActor : Actor -> Repo -> Repo
setActor actor repo =
    case actor of
        Actor.User user ->
            setSpaceUser user repo

        Actor.Bot bot ->
            setSpaceBot bot repo



-- GROUPS


getGroup : String -> Repo -> Maybe Group
getGroup id (Repo data) =
    Dict.get id data.groups


getGroups : List String -> Repo -> List Group
getGroups ids repo =
    List.filterMap (\id -> getGroup id repo) ids


setGroup : Group -> Repo -> Repo
setGroup group (Repo data) =
    Repo { data | groups = Dict.insert (Group.id group) group data.groups }


setGroups : List Group -> Repo -> Repo
setGroups groups repo =
    List.foldr setGroup repo groups



-- POSTS


getPost : Id -> Repo -> Maybe Post
getPost id (Repo data) =
    Dict.get id data.posts


getPosts : List Id -> Repo -> List Post
getPosts ids repo =
    List.filterMap (\id -> getPost id repo) ids


setPost : Post -> Repo -> Repo
setPost post (Repo data) =
    Repo { data | posts = Dict.insert (Post.id post) post data.posts }


setPosts : List Post -> Repo -> Repo
setPosts posts repo =
    List.foldr setPost repo posts



-- REPLIES


getReply : String -> Repo -> Maybe Reply
getReply id (Repo data) =
    Dict.get id data.replies


getReplies : List String -> Repo -> List Reply
getReplies ids repo =
    List.filterMap (\id -> getReply id repo) ids


setReply : Reply -> Repo -> Repo
setReply reply (Repo data) =
    Repo { data | replies = Dict.insert (Reply.id reply) reply data.replies }


setReplies : List Reply -> Repo -> Repo
setReplies replies repo =
    List.foldr setReply repo replies
