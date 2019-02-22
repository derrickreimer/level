module ReplySet exposing
    ( ReplySet, State(..)
    , empty, load, isLoaded, setLoaded
    , get, update, add, addPrev
    , map, isEmpty, firstPostedAt
    , sortByPostedAt
    )

{-| A ReplySet represents a timeline of replies.


# Types

@docs ReplySet, State


# Initialization

@docs empty, load, isLoaded, setLoaded


# Operations

@docs get, update, add, addPrev


# Inspection

@docs map, isEmpty, firstPostedAt


# Sorting

@docs sortByPostedAt

-}

import Connection exposing (Connection)
import Globals exposing (Globals)
import Id exposing (Id)
import ListHelpers exposing (getBy, memberBy, updateBy)
import Post
import Reply exposing (Reply)
import ReplyView exposing (ReplyView)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Set exposing (Set)
import Time exposing (Posix)


type ReplySet
    = ReplySet Internal


type State
    = Loading
    | Loaded


type alias Internal =
    { views : List ReplyView
    , state : State
    }



-- INITIALIZATION


empty : ReplySet
empty =
    ReplySet (Internal [] Loading)


load : Id -> List Reply -> ReplySet -> ReplySet
load spaceId replies (ReplySet internal) =
    let
        newViews =
            List.map (ReplyView.init spaceId) replies
    in
    ReplySet { internal | views = newViews, state = Loaded }


isLoaded : ReplySet -> Bool
isLoaded (ReplySet internal) =
    internal.state == Loaded


setLoaded : ReplySet -> ReplySet
setLoaded (ReplySet internal) =
    ReplySet { internal | state = Loaded }



-- OPERATIONS


get : Id -> ReplySet -> Maybe ReplyView
get id (ReplySet internal) =
    internal.views
        |> getBy .id id


update : ReplyView -> ReplySet -> ReplySet
update replyView (ReplySet internal) =
    let
        replacer current =
            if current.id == replyView.id then
                replyView

            else
                current
    in
    ReplySet { internal | views = List.map replacer internal.views }


add : Id -> Reply -> ReplySet -> ReplySet
add spaceId reply (ReplySet internal) =
    let
        newView =
            ReplyView.init spaceId reply
    in
    ReplySet { internal | views = List.append internal.views [ newView ] }


addPrev : Id -> List Reply -> ReplySet -> ReplySet
addPrev spaceId replies (ReplySet internal) =
    let
        newViews =
            List.map (ReplyView.init spaceId) replies
    in
    ReplySet { internal | views = List.append newViews internal.views }



-- INSPECTION


map : (ReplyView -> b) -> ReplySet -> List b
map fn (ReplySet internal) =
    List.map fn internal.views


isEmpty : ReplySet -> Bool
isEmpty (ReplySet internal) =
    List.isEmpty internal.views


firstPostedAt : ReplySet -> Maybe Posix
firstPostedAt (ReplySet internal) =
    internal.views
        |> List.head
        |> Maybe.andThen (Just << .postedAt)



-- SORTING


sortByPostedAt : ReplySet -> ReplySet
sortByPostedAt (ReplySet internal) =
    let
        sorter a b =
            case compare (a.postedAt |> Time.posixToMillis) (b.postedAt |> Time.posixToMillis) of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT
    in
    ReplySet { internal | views = List.sortWith sorter internal.views }
