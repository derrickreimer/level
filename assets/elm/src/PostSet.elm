module PostSet exposing
    ( PostSet, State(..)
    , empty, loadCached, isLoaded, setLoaded
    , get, update, remove, add, enqueue
    , toList, mapList, isEmpty, lastPostedAt, queueDepth
    , select, selectPrev, selectNext, selected
    , sortByPostedAt
    )

{-| A PostSet represents a timeline of posts.


# Types

@docs PostSet, State


# Initialization

@docs empty, loadCached, isLoaded, setLoaded


# Operations

@docs get, update, remove, add, enqueue, flushQueue


# Inspection

@docs toList, mapList, isEmpty, lastPostedAt, queueDepth


# Selection

@docs select, selectPrev, selectNext, selected


# Sorting

@docs sortByPostedAt

-}

import Connection exposing (Connection)
import Globals exposing (Globals)
import Id exposing (Id)
import ListHelpers exposing (getBy, memberBy, updateBy)
import Post exposing (Post)
import PostView exposing (PostView)
import Reply
import Repo exposing (Repo)
import Set exposing (Set)
import Time exposing (Posix)
import Vendor.SelectList as SelectList exposing (SelectList)


type PostSet
    = PostSet Internal


type Views
    = Empty
    | NonEmpty (SelectList PostView)


type State
    = Loading
    | Loaded


type alias Internal =
    { views : Views
    , queue : Set Id
    , state : State
    }



-- INITIALIZATION


empty : PostSet
empty =
    PostSet (Internal Empty Set.empty Loading)


loadCached : Globals -> List Post -> PostSet -> ( PostSet, List ( Id, Cmd PostView.Msg ) )
loadCached globals posts (PostSet internal) =
    let
        newViewList =
            List.map (PostView.init globals.repo 3) posts

        newViews =
            case newViewList of
                [] ->
                    Empty

                hd :: tl ->
                    NonEmpty (SelectList.fromLists [] hd tl)

        cmds =
            List.map (\view -> ( view.id, PostView.setup globals view )) newViewList
    in
    ( PostSet { internal | views = newViews, state = Loaded }, cmds )


isLoaded : PostSet -> Bool
isLoaded (PostSet internal) =
    internal.state == Loaded


setLoaded : PostSet -> PostSet
setLoaded (PostSet internal) =
    PostSet { internal | state = Loaded }



-- OPERATIONS


get : Id -> PostSet -> Maybe PostView
get id postSet =
    postSet
        |> toList
        |> getBy .id id


update : PostView -> PostSet -> PostSet
update postView (PostSet internal) =
    let
        replacer current =
            if current.id == postView.id then
                postView

            else
                current

        newViews =
            case internal.views of
                Empty ->
                    Empty

                NonEmpty slist ->
                    NonEmpty (SelectList.map replacer slist)
    in
    PostSet { internal | views = newViews }


remove : Id -> PostSet -> PostSet
remove id (PostSet internal) =
    let
        newComps =
            case internal.views of
                Empty ->
                    Empty

                NonEmpty slist ->
                    let
                        before =
                            SelectList.before slist

                        after =
                            SelectList.after slist

                        currentlySelected =
                            SelectList.selected slist
                    in
                    if currentlySelected.id == id then
                        case ( List.reverse before, after ) of
                            ( [], [] ) ->
                                Empty

                            ( hd :: tl, [] ) ->
                                NonEmpty (SelectList.fromLists (List.reverse tl) hd [])

                            ( _, hd :: tl ) ->
                                NonEmpty (SelectList.fromLists before hd tl)

                    else
                        let
                            newBefore =
                                List.filter (\node -> not (node.id == id)) before

                            newAfter =
                                List.filter (\node -> not (node.id == id)) after
                        in
                        NonEmpty (SelectList.fromLists newBefore currentlySelected newAfter)
    in
    PostSet { internal | views = newComps }


add : Globals -> Post -> PostSet -> ( PostSet, Cmd PostView.Msg )
add globals post postSet =
    let
        ( newPostSet, cmds ) =
            flushPost globals post ( postSet, [] )

        cmd =
            cmds
                |> List.head
                |> Maybe.withDefault Cmd.none
    in
    ( newPostSet, cmd )


enqueue : Id -> PostSet -> PostSet
enqueue postId (PostSet internal) =
    PostSet { internal | queue = Set.insert postId internal.queue }



-- INSPECTION


toList : PostSet -> List PostView
toList (PostSet internal) =
    case internal.views of
        Empty ->
            []

        NonEmpty slist ->
            SelectList.toList slist


mapList : (PostView -> b) -> PostSet -> List b
mapList fn postSet =
    List.map fn (toList postSet)


isEmpty : PostSet -> Bool
isEmpty (PostSet internal) =
    internal.views == Empty


lastPostedAt : PostSet -> Maybe Posix
lastPostedAt postSet =
    postSet
        |> toList
        |> List.reverse
        |> List.head
        |> Maybe.andThen (Just << .postedAt)


queueDepth : PostSet -> Int
queueDepth (PostSet internals) =
    Set.size internals.queue



-- SELECTION


select : Id -> PostSet -> PostSet
select id (PostSet internal) =
    case internal.views of
        Empty ->
            PostSet internal

        NonEmpty slist ->
            let
                newComps =
                    SelectList.select (\item -> item.id == id) slist
            in
            PostSet { internal | views = NonEmpty newComps }


selectPrev : PostSet -> PostSet
selectPrev (PostSet internal) =
    let
        newComps =
            case internal.views of
                Empty ->
                    Empty

                NonEmpty slist ->
                    case List.reverse (SelectList.before slist) of
                        [] ->
                            NonEmpty slist

                        newSelected :: newBeforeReversed ->
                            NonEmpty <|
                                SelectList.fromLists
                                    (List.reverse newBeforeReversed)
                                    newSelected
                                    (SelectList.selected slist :: SelectList.after slist)
    in
    PostSet { internal | views = newComps }


selectNext : PostSet -> PostSet
selectNext (PostSet internal) =
    let
        newComps =
            case internal.views of
                Empty ->
                    Empty

                NonEmpty slist ->
                    case SelectList.after slist of
                        [] ->
                            NonEmpty slist

                        newSelected :: newAfter ->
                            NonEmpty <|
                                SelectList.fromLists
                                    (SelectList.before slist ++ [ SelectList.selected slist ])
                                    newSelected
                                    newAfter
    in
    PostSet { internal | views = newComps }


selected : PostSet -> Maybe PostView
selected (PostSet internal) =
    case internal.views of
        Empty ->
            Nothing

        NonEmpty slist ->
            Just <| SelectList.selected slist



-- SORTING


sortByPostedAt : PostSet -> PostSet
sortByPostedAt ((PostSet internal) as postSet) =
    let
        sorter a b =
            case compare (a.postedAt |> Time.posixToMillis) (b.postedAt |> Time.posixToMillis) of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT

        sortedList =
            postSet
                |> toList
                |> List.sortWith sorter
    in
    case sortedList of
        [] ->
            postSet

        hd :: tl ->
            PostSet { internal | views = NonEmpty (SelectList.fromLists [] hd tl) }



-- PRIVATE


flushPost : Globals -> Post -> ( PostSet, List (Cmd PostView.Msg) ) -> ( PostSet, List (Cmd PostView.Msg) )
flushPost globals post ( PostSet internal, cmds ) =
    let
        newComp =
            PostView.init globals.repo 3 post

        setupCmd =
            PostView.setup globals newComp

        ( newComps, newCmds ) =
            case internal.views of
                Empty ->
                    ( NonEmpty (SelectList.fromLists [] newComp []), setupCmd :: cmds )

                NonEmpty slist ->
                    if memberBy .id newComp (SelectList.toList slist) then
                        ( NonEmpty slist, cmds )

                    else
                        ( NonEmpty (SelectList.prepend [ newComp ] slist), setupCmd :: cmds )
    in
    ( PostSet { internal | views = newComps }, newCmds )
