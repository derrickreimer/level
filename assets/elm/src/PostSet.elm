module PostSet exposing
    ( PostSet, State(..)
    , empty, loadCached, isScaffolded, isLoaded, isLoadingMore, setLoaded, setLoadingMore
    , get, update, remove, add, enqueue, flushQueue, mapCommands, hasMore, setHasMore
    , toList, mapList, isEmpty, lastPostedAt, queueDepth
    , select, selectPrev, selectNext, selected
    , sortByPostedAt
    )

{-| A PostSet represents a timeline of posts.


# Types

@docs PostSet, State


# Initialization

@docs empty, loadCached, isScaffolded, isLoaded, isLoadingMore, setLoaded, setLoadingMore


# Operations

@docs get, update, remove, add, enqueue, flushQueue, mapCommands, hasMore, setHasMore


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
    = Scaffolding
    | Loaded
    | LoadingMore


type alias Internal =
    { views : Views
    , queue : Set Id
    , state : State
    , hasMore : Bool
    }



-- INITIALIZATION


empty : PostSet
empty =
    PostSet (Internal Empty Set.empty Scaffolding True)


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


isScaffolded : PostSet -> Bool
isScaffolded (PostSet internal) =
    internal.state /= Scaffolding


isLoaded : PostSet -> Bool
isLoaded (PostSet internal) =
    internal.state == Loaded


isLoadingMore : PostSet -> Bool
isLoadingMore (PostSet internal) =
    internal.state == LoadingMore


setLoaded : PostSet -> PostSet
setLoaded (PostSet internal) =
    PostSet { internal | state = Loaded }


setLoadingMore : PostSet -> PostSet
setLoadingMore (PostSet internal) =
    PostSet { internal | state = LoadingMore }



-- OPERATIONS


get : Id -> PostSet -> Maybe PostView
get id postSet =
    postSet
        |> toList
        |> getBy .id id


update : PostView -> PostSet -> PostSet
update postView (PostSet internal) =
    PostSet { internal | views = updateView postView internal.views }


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
                |> Maybe.map Tuple.second
                |> Maybe.withDefault Cmd.none
    in
    ( newPostSet, cmd )


enqueue : Id -> PostSet -> PostSet
enqueue postId ((PostSet internal) as postSet) =
    case get postId postSet of
        Just _ ->
            postSet

        Nothing ->
            PostSet { internal | queue = Set.insert postId internal.queue }


flushQueue : Globals -> PostSet -> ( PostSet, List ( Id, Cmd PostView.Msg ) )
flushQueue globals ((PostSet internal) as postSet) =
    let
        postIds =
            internal.queue
                |> Set.toList

        posts =
            globals.repo
                |> Repo.getPosts postIds
                |> List.sortWith Post.desc
    in
    List.foldr (flushPost globals) ( postSet, [] ) posts


mapCommands : (Id -> PostView.Msg -> msg) -> ( PostSet, List ( Id, Cmd PostView.Msg ) ) -> ( PostSet, Cmd msg )
mapCommands toMsg ( postSet, cmds ) =
    let
        batch =
            cmds
                |> List.map (\( id, cmd ) -> Cmd.map (toMsg id) cmd)
                |> Cmd.batch
    in
    ( postSet, batch )


hasMore : PostSet -> Bool
hasMore (PostSet internal) =
    internal.hasMore


setHasMore : Bool -> PostSet -> PostSet
setHasMore truth (PostSet internal) =
    PostSet { internal | hasMore = truth }



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


flushPost : Globals -> Post -> ( PostSet, List ( Id, Cmd PostView.Msg ) ) -> ( PostSet, List ( Id, Cmd PostView.Msg ) )
flushPost globals post ( (PostSet internal) as postSet, cmds ) =
    let
        postId =
            Post.id post

        newView =
            PostView.init globals.repo 3 post

        setupCmd =
            PostView.setup globals newView

        ( newViews, newCmds ) =
            case internal.views of
                Empty ->
                    ( NonEmpty (SelectList.fromLists [] newView []), ( postId, setupCmd ) :: cmds )

                NonEmpty slist ->
                    case ListHelpers.getBy .id newView.id (SelectList.toList slist) of
                        Just currentView ->
                            let
                                ( refreshedView, refreshCmd ) =
                                    PostView.refreshFromCache globals currentView
                            in
                            ( updateView refreshedView internal.views, ( postId, refreshCmd ) :: cmds )

                        Nothing ->
                            ( NonEmpty (SelectList.prepend [ newView ] slist), ( postId, setupCmd ) :: cmds )
    in
    ( PostSet { internal | views = newViews, queue = Set.remove (Post.id post) internal.queue }, newCmds )


updateView : PostView -> Views -> Views
updateView postView views =
    let
        replacer current =
            if current.id == postView.id then
                postView

            else
                current
    in
    case views of
        Empty ->
            Empty

        NonEmpty slist ->
            NonEmpty (SelectList.map replacer slist)
