module PostSet exposing (PostSet, State(..), empty, get, isEmpty, isLoaded, load, mapList, prepend, remove, select, selectNext, selectPrev, selected, setLoaded, sortByPostedAt, toList, update)

import Component.Post
import Connection exposing (Connection)
import Globals exposing (Globals)
import Id exposing (Id)
import ListHelpers exposing (getBy, memberBy, updateBy)
import Post
import Reply
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Time
import Vendor.SelectList as SelectList exposing (SelectList)


type PostSet
    = PostSet Internal


type Components
    = Empty
    | NonEmpty (SelectList Component.Post.Model)


type State
    = Loading
    | Loaded


type alias Internal =
    { comps : Components
    , state : State
    }


empty : PostSet
empty =
    PostSet (Internal Empty Loading)


load : List ResolvedPostWithReplies -> PostSet -> PostSet
load resolvedPosts (PostSet internal) =
    let
        newComps =
            case List.map buildComponent resolvedPosts of
                [] ->
                    Empty

                hd :: tl ->
                    NonEmpty (SelectList.fromLists [] hd tl)
    in
    PostSet { internal | comps = newComps, state = Loaded }


isLoaded : PostSet -> Bool
isLoaded (PostSet internal) =
    internal.state == Loaded


setLoaded : PostSet -> PostSet
setLoaded (PostSet internal) =
    PostSet { internal | state = Loaded }


get : Id -> PostSet -> Maybe Component.Post.Model
get id postSet =
    postSet
        |> toList
        |> getBy .id id


selected : PostSet -> Maybe Component.Post.Model
selected (PostSet internal) =
    case internal.comps of
        Empty ->
            Nothing

        NonEmpty slist ->
            Just <| SelectList.selected slist


update : Component.Post.Model -> PostSet -> PostSet
update postComp (PostSet internal) =
    let
        replacer current =
            if current.id == postComp.id then
                postComp

            else
                current

        newComps =
            case internal.comps of
                Empty ->
                    Empty

                NonEmpty slist ->
                    NonEmpty (SelectList.map replacer slist)
    in
    PostSet { internal | comps = newComps }


remove : Id -> PostSet -> PostSet
remove id (PostSet internal) =
    let
        newComps =
            case internal.comps of
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
    PostSet { internal | comps = newComps }


select : Id -> PostSet -> PostSet
select id (PostSet internal) =
    case internal.comps of
        Empty ->
            PostSet internal

        NonEmpty slist ->
            let
                newComps =
                    SelectList.select (\item -> item.id == id) slist
            in
            PostSet { internal | comps = NonEmpty newComps }


selectPrev : PostSet -> PostSet
selectPrev (PostSet internal) =
    let
        newComps =
            case internal.comps of
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
    PostSet { internal | comps = newComps }


selectNext : PostSet -> PostSet
selectNext (PostSet internal) =
    let
        newComps =
            case internal.comps of
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
    PostSet { internal | comps = newComps }


prepend : Globals -> ResolvedPostWithReplies -> PostSet -> ( PostSet, Cmd Component.Post.Msg )
prepend globals resolvedPost (PostSet internal) =
    let
        newComp =
            buildComponent resolvedPost

        setupCmd =
            Component.Post.setup globals newComp

        ( newComps, cmd ) =
            case internal.comps of
                Empty ->
                    ( NonEmpty (SelectList.fromLists [] newComp []), setupCmd )

                NonEmpty slist ->
                    if memberBy .id newComp (SelectList.toList slist) then
                        ( NonEmpty slist, Cmd.none )

                    else
                        ( NonEmpty (SelectList.prepend [ newComp ] slist), setupCmd )
    in
    ( PostSet { internal | comps = newComps }, cmd )


toList : PostSet -> List Component.Post.Model
toList (PostSet internal) =
    case internal.comps of
        Empty ->
            []

        NonEmpty slist ->
            SelectList.toList slist


mapList : (Component.Post.Model -> b) -> PostSet -> List b
mapList fn postSet =
    List.map fn (toList postSet)


isEmpty : PostSet -> Bool
isEmpty (PostSet internal) =
    internal.comps == Empty



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
            PostSet { internal | comps = NonEmpty (SelectList.fromLists [] hd tl) }



-- PRIVATE


buildComponent : ResolvedPostWithReplies -> Component.Post.Model
buildComponent resolvedPost =
    let
        post =
            resolvedPost.post

        replies =
            Connection.map .reply resolvedPost.resolvedReplies
    in
    Component.Post.init resolvedPost
