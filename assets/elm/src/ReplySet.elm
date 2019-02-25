module ReplySet exposing
    ( ReplySet, State(..)
    , empty, load, isLoaded, setLoaded
    , get, update, append, appendMany, prepend, prependMany, removeDeleted, hasMore, setHasMore
    , map, isEmpty, firstPostedAt, lastPostedAt
    , sortByPostedAt
    )

{-| A ReplySet represents a timeline of replies.


# Types

@docs ReplySet, State


# Initialization

@docs empty, load, isLoaded, setLoaded


# Operations

@docs get, update, append, appendMany, prepend, prependMany, removeDeleted, hasMore, setHasMore


# Inspection

@docs map, isEmpty, firstPostedAt, lastPostedAt


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
import Repo exposing (Repo)
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
    , hasMore : Bool
    }



-- INITIALIZATION


empty : ReplySet
empty =
    ReplySet (Internal [] Loading False)


load : Id -> List Reply -> ReplySet -> ReplySet
load spaceId replies (ReplySet internal) =
    let
        newViews =
            List.map (ReplyView.init spaceId) replies
    in
    ReplySet { internal | views = newViews, state = Loaded, hasMore = List.length newViews >= 3 }


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


append : Id -> Reply -> ReplySet -> ReplySet
append spaceId reply (ReplySet internal) =
    if List.any (\view -> view.id == Reply.id reply) internal.views then
        ReplySet internal

    else
        ReplySet { internal | views = List.append internal.views [ ReplyView.init spaceId reply ] }


appendMany : Id -> List Reply -> ReplySet -> ReplySet
appendMany spaceId replies replySet =
    List.foldl (append spaceId) replySet replies


prepend : Id -> Reply -> ReplySet -> ReplySet
prepend spaceId reply (ReplySet internal) =
    if List.any (\view -> view.id == Reply.id reply) internal.views then
        ReplySet internal

    else
        ReplySet { internal | views = ReplyView.init spaceId reply :: internal.views }


prependMany : Id -> List Reply -> ReplySet -> ReplySet
prependMany spaceId replies replySet =
    List.foldr (prepend spaceId) replySet replies


removeDeleted : Repo -> ReplySet -> ReplySet
removeDeleted repo (ReplySet internal) =
    let
        filterFn repo2 view =
            case Repo.getReply view.id repo2 of
                Just reply ->
                    if Reply.notDeleted reply then
                        Just view

                    else
                        Nothing

                Nothing ->
                    Nothing

        newViews =
            internal.views
                |> List.filterMap (filterFn repo)
    in
    ReplySet { internal | views = newViews }


hasMore : ReplySet -> Bool
hasMore (ReplySet internal) =
    internal.hasMore


setHasMore : Bool -> ReplySet -> ReplySet
setHasMore truth (ReplySet internal) =
    ReplySet { internal | hasMore = truth }



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


lastPostedAt : ReplySet -> Maybe Posix
lastPostedAt (ReplySet internal) =
    internal.views
        |> List.reverse
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
