module Page.Search exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Event exposing (Event)
import FieldEditor exposing (FieldEditor)
import File exposing (File)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Icons
import Id exposing (Id)
import Json.Decode as Decode
import ListHelpers exposing (insertUniqueBy, removeBy)
import Pagination
import Post
import PostSearchResult
import Query.SearchInit as SearchInit
import RenderedHtml
import Reply
import ReplySearchResult
import Repo exposing (Repo)
import ResolvedPostSearchResult exposing (ResolvedPostSearchResult)
import ResolvedReplySearchResult exposing (ResolvedReplySearchResult)
import ResolvedSearchResult exposing (ResolvedSearchResult)
import Route exposing (Route)
import Route.Group
import Route.Search exposing (Params)
import Scroll
import SearchResult exposing (SearchResult)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import ValidationError exposing (ValidationError, errorView, errorsFor, errorsNotFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (onPassiveClick)
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , searchResults : Connection SearchResult
    , queryEditor : FieldEditor String
    , now : ( Zone, Posix )
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , resolvedSearchResults : Connection ResolvedSearchResult
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)
        (Just <| Connection.filterMap (ResolvedSearchResult.resolve repo) model.searchResults)



-- PAGE PROPERTIES


title : Model -> String
title model =
    "Search"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SearchInit.request params
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( ( Session, SearchInit.Response ), ( Zone, Posix ) ) -> ( Globals, Model )
buildModel params globals ( ( newSession, resp ), now ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                resp.searchResults
                (FieldEditor.init "search-editor" (Route.Search.getQuery params |> Maybe.withDefault ""))
                now

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.batch
        [ Scroll.toDocumentTop NoOp
        , View.Helpers.selectValue (FieldEditor.getNodeId model.queryEditor)
        ]


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = SearchEditorChanged String
    | SearchSubmitted
    | Tick Posix
    | SetCurrentTime Posix Zone
    | ClickedToExpand Route
    | NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), globals )

        SetCurrentTime posix zone ->
            noCmd globals { model | now = ( zone, posix ) }

        SearchEditorChanged newValue ->
            ( ( { model | queryEditor = FieldEditor.setValue newValue model.queryEditor }, Cmd.none ), globals )

        SearchSubmitted ->
            let
                newQueryEditor =
                    model.queryEditor
                        |> FieldEditor.setIsSubmitting True

                searchParams =
                    Route.Search.init
                        (Route.Search.getSpaceSlug model.params)
                        (FieldEditor.getValue newQueryEditor)

                cmd =
                    Route.pushUrl globals.navKey (Route.Search searchParams)
            in
            ( ( { model | queryEditor = newQueryEditor }, cmd ), globals )

        ClickedToExpand route ->
            ( ( model, Route.pushUrl globals.navKey route ), globals )

        NoOp ->
            noCmd globals model


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every 1000 Tick



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    case resolveData repo model of
        Just data ->
            resolvedView repo maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> Maybe Route -> Model -> Data -> Html Msg
resolvedView repo maybeCurrentRoute model data =
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ div [ class "sticky pin-t mb-3 pt-4 bg-white z-50" ]
                [ div [ class "pb-4 border-b" ]
                    [ div [ class "flex items-center" ]
                        [ h2 [ class "flex-no-shrink font-extrabold text-2xl" ] [ text "Search" ]
                        , controlsView model data
                        ]
                    ]
                ]
            , resultsView repo model.params model.now data.resolvedSearchResults
            ]
        ]


controlsView : Model -> Data -> Html Msg
controlsView model data =
    div [ class "flex items-center flex-grow justify-end" ]
        [ queryEditorView model.queryEditor
        , paginationView model.params model.searchResults
        ]


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (\beforeCursor -> Route.Search (Route.Search.setCursors (Just beforeCursor) Nothing params))
        (\afterCursor -> Route.Search (Route.Search.setCursors Nothing (Just afterCursor) params))


queryEditorView : FieldEditor String -> Html Msg
queryEditorView editor =
    label [ class "flex items-center mr-6 py-2 px-3 rounded bg-grey-light" ]
        [ div [ class "mr-2" ] [ Icons.search ]
        , input
            [ id (FieldEditor.getNodeId editor)
            , type_ "text"
            , class "bg-transparent text-sm text-dusty-blue-darker no-outline"
            , value (FieldEditor.getValue editor)
            , readonly (FieldEditor.isSubmitting editor)
            , onInput SearchEditorChanged
            , onKeydown preventDefault
                [ ( [], enter, \event -> SearchSubmitted )
                ]
            ]
            []
        ]


resultsView : Repo -> Params -> ( Zone, Posix ) -> Connection ResolvedSearchResult -> Html Msg
resultsView repo params now taggedResults =
    if Connection.isEmptyAndExpanded taggedResults then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "This search turned up no results!" ]

    else
        div [] <|
            Connection.mapList (resultView repo params now) taggedResults


resultView : Repo -> Params -> ( Zone, Posix ) -> ResolvedSearchResult -> Html Msg
resultView repo params now taggedResult =
    case taggedResult of
        ResolvedSearchResult.Post result ->
            postResultView repo params now result

        ResolvedSearchResult.Reply result ->
            replyResultView repo params now result


postResultView : Repo -> Params -> ( Zone, Posix ) -> ResolvedPostSearchResult -> Html Msg
postResultView repo params now resolvedResult =
    let
        postRoute =
            Route.Post (Route.Search.getSpaceSlug params) (Post.id resolvedResult.resolvedPost.post)
    in
    div [ class "flex py-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ SpaceUser.avatar Avatar.Medium resolvedResult.resolvedPost.author ]
        , div [ class "flex-grow min-w-0 leading-semi-loose" ]
            [ div []
                [ authorLabel postRoute resolvedResult.resolvedPost.author
                , groupsLabel params resolvedResult.resolvedPost.groups
                , timestampLabel postRoute now (Post.postedAt resolvedResult.resolvedPost.post)
                ]
            , clickToExpand postRoute
                [ div [ class "markdown mb-2" ]
                    [ RenderedHtml.node (Post.bodyHtml resolvedResult.resolvedPost.post) ]
                ]
            ]
        ]


replyResultView : Repo -> Params -> ( Zone, Posix ) -> ResolvedReplySearchResult -> Html Msg
replyResultView repo params now resolvedResult =
    let
        replyRoute =
            Route.Post (Route.Search.getSpaceSlug params) (Post.id resolvedResult.resolvedPost.post)
    in
    div [ class "flex py-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ SpaceUser.avatar Avatar.Medium resolvedResult.resolvedReply.author ]
        , div [ class "flex-grow min-w-0 leading-semi-loose" ]
            [ div []
                [ div [ class "mr-2 inline-block" ] [ Icons.reply ]
                , authorLabel replyRoute resolvedResult.resolvedReply.author
                , groupsLabel params resolvedResult.resolvedPost.groups
                , timestampLabel replyRoute now (Reply.postedAt resolvedResult.resolvedReply.reply)
                ]
            , clickToExpand replyRoute
                [ div [ class "markdown mb-2" ]
                    [ RenderedHtml.node (Reply.bodyHtml resolvedResult.resolvedReply.reply) ]
                ]
            ]
        ]


authorLabel : Route -> SpaceUser -> Html Msg
authorLabel route author =
    a
        [ Route.href route
        , class "no-underline text-dusty-blue-darkest whitespace-no-wrap font-bold"
        , rel "tooltip"
        , Html.Attributes.title "Expand post"
        ]
        [ text <| SpaceUser.displayName author ]


timestampLabel : Route -> ( Zone, Posix ) -> Posix -> Html Msg
timestampLabel route (( zone, _ ) as now) time =
    a
        [ Route.href route
        , class "no-underline whitespace-no-wrap"
        , rel "tooltip"
        , Html.Attributes.title "Expand post"
        ]
        [ View.Helpers.time now
            ( zone, time )
            [ class "ml-3 text-sm text-dusty-blue" ]
        ]


groupsLabel : Params -> List Group -> Html Msg
groupsLabel params groups =
    case groups of
        [ group ] ->
            span [ class "ml-3 text-sm text-dusty-blue" ]
                [ a
                    [ Route.href (Route.Group (Route.Group.init (Route.Search.getSpaceSlug params) (Group.id group)))
                    , class "no-underline text-dusty-blue font-bold whitespace-no-wrap"
                    ]
                    [ text (Group.name group) ]
                ]

        _ ->
            text ""


clickToExpand : Route -> List (Html Msg) -> Html Msg
clickToExpand route children =
    div [ class "cursor-pointer select-none", onPassiveClick (ClickedToExpand route) ] children
