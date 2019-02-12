module Page.Search exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Actor exposing (Actor)
import Avatar
import Browser.Navigation as Nav
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
import Layout.SpaceDesktop
import ListHelpers exposing (insertUniqueBy, removeBy)
import OffsetConnection exposing (OffsetConnection)
import OffsetPagination
import Post
import PostSearchResult
import Query.SearchInit as SearchInit
import RenderedHtml
import Reply
import ReplySearchResult
import Repo exposing (Repo)
import ResolvedAuthor exposing (ResolvedAuthor)
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
import View.SearchBox



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , searchResults : OffsetConnection SearchResult
    , queryEditor : FieldEditor String
    , now : ( Zone, Posix )
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , resolvedSearchResults : OffsetConnection ResolvedSearchResult
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| OffsetConnection.filterMap (ResolvedSearchResult.resolve repo) model.searchResults)



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
        editor =
            Route.Search.getQuery params
                |> Maybe.withDefault ""
                |> FieldEditor.init "search-editor"
                |> FieldEditor.expand

        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.searchResults
                editor
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
    = ToggleKeyboardCommands
    | SearchEditorChanged String
    | SearchSubmitted
    | Tick Posix
    | SetCurrentTime Posix Zone
    | ClickedToExpand Route
    | InternalLinkClicked String
    | NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

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

        InternalLinkClicked pathname ->
            ( ( model, Nav.pushUrl globals.navKey pathname ), globals )

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
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every 1000 Tick



-- VIEW


view : Globals -> Model -> Html Msg
view globals model =
    case resolveData globals.repo model of
        Just data ->
            resolvedView globals model data

        Nothing ->
            text "Something went wrong."


resolvedView : Globals -> Model -> Data -> Html Msg
resolvedView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , showKeyboardCommands = globals.showKeyboardCommands
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 max-w-lg leading-normal" ]
            [ div [ class "sticky pin-t mb-3 pt-4 bg-white z-50" ]
                [ div [ class "pb-4 border-b" ]
                    [ div [ class "flex items-center" ]
                        [ h2 [ class "flex-no-shrink font-bold text-2xl" ] [ text "Search" ]
                        , controlsView model data
                        ]
                    ]
                ]
            , resultsView globals.repo model.params model.now data
            , div [ class "p-8 pb-16" ]
                [ paginationView model.params model.searchResults
                ]
            ]
        ]


controlsView : Model -> Data -> Html Msg
controlsView model data =
    div [ class "flex items-center flex-grow justify-end" ]
        [ queryEditorView model.queryEditor
        ]


paginationView : Params -> OffsetConnection a -> Html Msg
paginationView params connection =
    OffsetPagination.view connection
        (Route.Search (Route.Search.decrementPage params))
        (Route.Search (Route.Search.incrementPage params))


queryEditorView : FieldEditor String -> Html Msg
queryEditorView editor =
    View.SearchBox.view
        { editor = editor
        , changeMsg = SearchEditorChanged
        , expandMsg = NoOp
        , collapseMsg = NoOp
        , submitMsg = SearchSubmitted
        }


resultsView : Repo -> Params -> ( Zone, Posix ) -> Data -> Html Msg
resultsView repo params now data =
    if OffsetConnection.isEmptyAndExpanded data.resolvedSearchResults then
        div [ class "pt-8 pb-8 font-headline text-center text-lg" ]
            [ text "This search turned up no results!" ]

    else
        data.resolvedSearchResults
            |> OffsetConnection.toList
            |> List.map (resultView repo params now data)
            |> div []


resultView : Repo -> Params -> ( Zone, Posix ) -> Data -> ResolvedSearchResult -> Html Msg
resultView repo params now data taggedResult =
    case taggedResult of
        ResolvedSearchResult.Post result ->
            postResultView repo params now data result

        ResolvedSearchResult.Reply result ->
            replyResultView repo params now data result


postResultView : Repo -> Params -> ( Zone, Posix ) -> Data -> ResolvedPostSearchResult -> Html Msg
postResultView repo params now data resolvedResult =
    let
        postRoute =
            Route.Post (Route.Search.getSpaceSlug params) (Post.id resolvedResult.resolvedPost.post)
    in
    div [ class "flex py-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Medium resolvedResult.resolvedPost.author) ]
        , div [ class "flex-grow min-w-0 normal" ]
            [ div [ class "pb-1/2" ]
                [ authorLabel postRoute (ResolvedAuthor.actor resolvedResult.resolvedPost.author)
                , timestampLabel postRoute now (Post.postedAt resolvedResult.resolvedPost.post)
                ]
            , groupsLabel data.space resolvedResult.resolvedPost.groups
            , clickToExpand postRoute
                [ div [ class "markdown mb-3/2" ]
                    [ RenderedHtml.node
                        { html = Post.bodyHtml resolvedResult.resolvedPost.post
                        , onInternalLinkClicked = InternalLinkClicked
                        }
                    ]
                ]
            ]
        ]


replyResultView : Repo -> Params -> ( Zone, Posix ) -> Data -> ResolvedReplySearchResult -> Html Msg
replyResultView repo params now data resolvedResult =
    let
        replyRoute =
            Route.Post (Route.Search.getSpaceSlug params) (Post.id resolvedResult.resolvedPost.post)
    in
    div [ class "flex py-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Medium resolvedResult.resolvedReply.author) ]
        , div [ class "flex-grow min-w-0 leading-normal" ]
            [ div [ class "pb-1/2" ]
                [ div [ class "mr-2 inline-block" ] [ Icons.reply ]
                , authorLabel replyRoute (ResolvedAuthor.actor resolvedResult.resolvedReply.author)
                , timestampLabel replyRoute now (Reply.postedAt resolvedResult.resolvedReply.reply)
                ]
            , groupsLabel data.space resolvedResult.resolvedPost.groups
            , clickToExpand replyRoute
                [ div [ class "markdown mb-3/2" ]
                    [ RenderedHtml.node
                        { html = Reply.bodyHtml resolvedResult.resolvedReply.reply
                        , onInternalLinkClicked = InternalLinkClicked
                        }
                    ]
                ]
            ]
        ]


authorLabel : Route -> Actor -> Html Msg
authorLabel route author =
    a
        [ Route.href route
        , class "no-underline text-dusty-blue-darkest whitespace-no-wrap font-bold"
        , rel "tooltip"
        , Html.Attributes.title "Expand post"
        ]
        [ text <| Actor.displayName author ]


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


groupsLabel : Space -> List Group -> Html Msg
groupsLabel space groups =
    let
        groupLink group =
            a
                [ Route.href (Route.Group (Route.Group.init (Space.slug space) (Group.name group)))
                , class "mr-1 no-underline text-dusty-blue-dark whitespace-no-wrap"
                ]
                [ text ("#" ++ Group.name group) ]

        groupLinks =
            List.map groupLink groups
    in
    if List.isEmpty groups then
        text ""

    else
        div [ class "pb-1 mr-3 text-base text-dusty-blue" ]
            [ text ""
            , span [] groupLinks
            ]


clickToExpand : Route -> List (Html Msg) -> Html Msg
clickToExpand route children =
    div [ class "cursor-pointer select-none", onPassiveClick (ClickedToExpand route) ] children
