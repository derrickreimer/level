module Page.Search exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Actor exposing (Actor)
import Avatar
import Browser.Navigation as Nav
import Device
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
import Layout.SpaceMobile
import Lazy exposing (Lazy(..))
import ListHelpers exposing (insertUniqueBy, removeBy)
import OffsetConnection exposing (OffsetConnection)
import OffsetPagination
import PageError exposing (PageError)
import Post
import PostSearchResult
import Query.SearchResults as SearchResults
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
import TimeWithZone exposing (TimeWithZone)
import ValidationError exposing (ValidationError, errorView, errorsFor, errorsNotFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (onPassiveClick, viewIf)
import View.SearchBox



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , searchResults : Lazy (List SearchResult)
    , hasMore : Bool
    , isLoadingMore : Bool
    , queryEditor : FieldEditor String
    , now : TimeWithZone

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , resolvedSearchResults : Lazy (List ResolvedSearchResult)
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    let
        resolvedSearchResults =
            case model.searchResults of
                Loaded searchResults ->
                    Just (Loaded <| List.filterMap (ResolvedSearchResult.resolve repo) searchResults)

                NotLoaded ->
                    Just NotLoaded
    in
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        resolvedSearchResults



-- PAGE PROPERTIES


title : Model -> String
title model =
    "Search"



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( Globals, Model )
init params globals =
    let
        maybeUserId =
            Session.getUserId globals.session

        maybeSpace =
            Repo.getSpaceBySlug (Route.Search.getSpaceSlug params) globals.repo

        maybeViewer =
            case ( maybeSpace, maybeUserId ) of
                ( Just space, Just userId ) ->
                    Repo.getSpaceUserByUserId (Space.id space) userId globals.repo

                _ ->
                    Nothing
    in
    case ( maybeViewer, maybeSpace ) of
        ( Just viewer, Just space ) ->
            TimeWithZone.now
                |> Task.andThen (\now -> Task.succeed (scaffold globals params viewer space now))

        _ ->
            Task.fail PageError.NotFound


scaffold : Globals -> Params -> SpaceUser -> Space -> TimeWithZone -> ( Globals, Model )
scaffold globals params viewer space now =
    let
        editor =
            Route.Search.getQuery params
                |> Maybe.withDefault ""
                |> FieldEditor.init "search-editor"
                |> FieldEditor.expand

        model =
            Model
                params
                (SpaceUser.id viewer)
                (Space.id space)
                NotLoaded
                False
                False
                editor
                now
                False
                False
    in
    ( globals, model )


setup : Globals -> Model -> Cmd Msg
setup globals model =
    Cmd.batch
        [ Scroll.toDocumentTop NoOp
        , View.Helpers.selectValue (FieldEditor.getNodeId model.queryEditor)
        , globals.session
            |> SearchResults.request (SearchResults.variables model.params Nothing)
            |> Task.attempt ResultsLoaded
        ]


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = ToggleKeyboardCommands
    | ToggleNotifications
    | SearchEditorChanged String
    | SearchSubmitted
    | Tick Posix
    | ClickedToExpand Route
    | InternalLinkClicked String
    | LoadMoreClicked
    | ResultsLoaded (Result Session.Error ( Session, SearchResults.Response ))
    | NoOp
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        ToggleNotifications ->
            ( ( model, Cmd.none ), { globals | showNotifications = not globals.showNotifications } )

        Tick posix ->
            ( ( { model | now = TimeWithZone.setPosix posix model.now }, Cmd.none ), globals )

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
                        (Just <| FieldEditor.getValue newQueryEditor)

                cmd =
                    Route.pushUrl globals.navKey (Route.Search searchParams)
            in
            ( ( { model | queryEditor = newQueryEditor }, cmd ), globals )

        ClickedToExpand route ->
            ( ( model, Route.pushUrl globals.navKey route ), globals )

        InternalLinkClicked pathname ->
            ( ( model, Nav.pushUrl globals.navKey pathname ), globals )

        LoadMoreClicked ->
            case model.searchResults of
                Loaded searchResults ->
                    let
                        maybeLastResult =
                            searchResults
                                |> List.reverse
                                |> List.head

                        cmd =
                            case maybeLastResult of
                                Just lastResult ->
                                    globals.session
                                        |> SearchResults.request (SearchResults.variables model.params (Just <| SearchResult.postedAt lastResult))
                                        |> Task.attempt ResultsLoaded

                                Nothing ->
                                    Cmd.none
                    in
                    ( ( model, cmd ), globals )

                NotLoaded ->
                    ( ( model, Cmd.none ), globals )

        ResultsLoaded (Ok ( newSession, resp )) ->
            let
                newGlobals =
                    { globals | repo = Repo.union resp.repo globals.repo, session = newSession }

                newSearchResults =
                    case model.searchResults of
                        Loaded searchResults ->
                            Loaded <| List.append searchResults resp.results

                        NotLoaded ->
                            Loaded resp.results

                hasMore =
                    List.length resp.results >= 20
            in
            ( ( { model
                    | searchResults = newSearchResults
                    , hasMore = hasMore
                }
              , Cmd.none
              )
            , newGlobals
            )

        ResultsLoaded (Err Session.Expired) ->
            redirectToLogin globals model

        ResultsLoaded (Err _) ->
            noCmd globals model

        NoOp ->
            noCmd globals model

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


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
    case globals.device of
        Device.Desktop ->
            resolvedDesktopView globals model data

        Device.Mobile ->
            resolvedMobileView globals model data



-- DESKTOP


resolvedDesktopView : Globals -> Model -> Data -> Html Msg
resolvedDesktopView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            , onPageClicked = NoOp
            , onToggleNotifications = ToggleNotifications
            , onInternalLinkClicked = InternalLinkClicked
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 max-w-lg leading-normal" ]
            [ div [ class "sticky pin-t mb-3 bg-white z-50" ]
                [ div [ class "py-3 border-b" ]
                    [ div [ class "flex items-center" ]
                        [ h2 [ class "flex-no-shrink font-bold text-2xl" ] [ text "Search" ]
                        , controlsView model data
                        ]
                    ]
                ]
            , resultsView globals.repo model.params model.now data
            , viewIf (model.hasMore && not model.isLoadingMore) <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , onClick LoadMoreClicked
                        ]
                        [ text "Load more..." ]
                    ]
            , viewIf model.isLoadingMore <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , disabled True
                        ]
                        [ text "Loading..." ]
                    ]
            ]
        ]


controlsView : Model -> Data -> Html Msg
controlsView model data =
    div [ class "flex items-center flex-grow justify-end" ]
        [ queryEditorView model.queryEditor
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = "Search"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.Back (Route.Root (Route.Search.getSpaceSlug model.params))
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "p-3" ]
            [ queryEditorView model.queryEditor
            , resultsView globals.repo model.params model.now data
            , viewIf (model.hasMore && not model.isLoadingMore) <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , onClick LoadMoreClicked
                        ]
                        [ text "Load more..." ]
                    ]
            , viewIf model.isLoadingMore <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , disabled True
                        ]
                        [ text "Loading..." ]
                    ]
            ]
        ]



-- SHARED


queryEditorView : FieldEditor String -> Html Msg
queryEditorView editor =
    View.SearchBox.view
        { editor = editor
        , changeMsg = SearchEditorChanged
        , expandMsg = NoOp
        , collapseMsg = NoOp
        , submitMsg = SearchSubmitted
        }


resultsView : Repo -> Params -> TimeWithZone -> Data -> Html Msg
resultsView repo params now data =
    case data.resolvedSearchResults of
        Loaded resolvedSearchResults ->
            if List.isEmpty resolvedSearchResults && Route.Search.getQuery params /= Nothing then
                div [ class "pt-8 pb-8 font-headline text-center text-lg" ]
                    [ text "This search turned up no results!" ]

            else
                resolvedSearchResults
                    |> List.map (resultView repo params now data)
                    |> div []

        NotLoaded ->
            div [ class "pt-8 pb-8 font-headline text-center text-lg" ]
                [ text "Loading..." ]


resultView : Repo -> Params -> TimeWithZone -> Data -> ResolvedSearchResult -> Html Msg
resultView repo params now data taggedResult =
    case taggedResult of
        ResolvedSearchResult.Post result ->
            postResultView repo params now data result

        ResolvedSearchResult.Reply result ->
            replyResultView repo params now data result


postResultView : Repo -> Params -> TimeWithZone -> Data -> ResolvedPostSearchResult -> Html Msg
postResultView repo params now data resolvedResult =
    let
        postRoute =
            Route.Post (Route.Search.getSpaceSlug params) (Post.id resolvedResult.resolvedPost.post)
    in
    div [ class "flex py-4" ]
        [ div [ class "flex-no-shrink mr-3" ] [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Medium resolvedResult.resolvedPost.author) ]
        , div [ class "flex-grow min-w-0 normal" ]
            [ div [ class "pb-1/2" ]
                [ authorLabel postRoute (ResolvedAuthor.actor resolvedResult.resolvedPost.author)
                , timestampLabel postRoute now (Post.postedAt resolvedResult.resolvedPost.post)
                ]
            , groupsLabel data.space resolvedResult.resolvedPost.groups
            , clickToExpand postRoute
                [ div [ class "markdown mb-3/2 break-words" ]
                    [ RenderedHtml.node
                        { html = PostSearchResult.preview resolvedResult.result
                        , onInternalLinkClicked = InternalLinkClicked
                        }
                    ]
                ]
            ]
        ]


replyResultView : Repo -> Params -> TimeWithZone -> Data -> ResolvedReplySearchResult -> Html Msg
replyResultView repo params now data resolvedResult =
    let
        replyRoute =
            Route.Post (Route.Search.getSpaceSlug params) (Post.id resolvedResult.resolvedPost.post)
    in
    div [ class "flex py-4" ]
        [ div [ class "flex-no-shrink mr-3" ] [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Medium resolvedResult.resolvedReply.author) ]
        , div [ class "flex-grow min-w-0 leading-normal" ]
            [ div [ class "pb-1/2" ]
                [ div [ class "mr-2 inline-block" ] [ Icons.reply ]
                , authorLabel replyRoute (ResolvedAuthor.actor resolvedResult.resolvedReply.author)
                , timestampLabel replyRoute now (Reply.postedAt resolvedResult.resolvedReply.reply)
                ]
            , groupsLabel data.space resolvedResult.resolvedPost.groups
            , clickToExpand replyRoute
                [ div [ class "markdown mb-3/2 break-words" ]
                    [ RenderedHtml.node
                        { html = ReplySearchResult.preview resolvedResult.result
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


timestampLabel : Route -> TimeWithZone -> Posix -> Html Msg
timestampLabel route now posix =
    a
        [ Route.href route
        , class "no-underline whitespace-no-wrap"
        , rel "tooltip"
        , Html.Attributes.title "Expand post"
        ]
        [ View.Helpers.timeTag now
            (TimeWithZone.setPosix posix now)
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
