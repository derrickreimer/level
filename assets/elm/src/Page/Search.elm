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
import Mutation.UpdateSpace as UpdateSpace
import Mutation.UpdateSpaceAvatar as UpdateSpaceAvatar
import Pagination
import Query.SearchInit as SearchInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Search exposing (Params)
import Scroll
import SearchResult exposing (SearchResult)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, errorsNotFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , searchResults : Connection SearchResult
    , queryEditor : FieldEditor String
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)



-- PAGE PROPERTIES


title : Model -> String
title model =
    "Search"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SearchInit.request params
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SearchInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                resp.searchResults
                (FieldEditor.init "search-editor" (Route.Search.getQuery params |> Maybe.withDefault ""))

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
    | NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
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
    Sub.none



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
            , resultsView repo model.searchResults
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
            , class "bg-transparent text-sm text-dusty-blue-dark no-outline"
            , value (FieldEditor.getValue editor)
            , readonly (FieldEditor.isSubmitting editor)
            , onInput SearchEditorChanged
            , onKeydown preventDefault
                [ ( [], enter, \event -> SearchSubmitted )
                ]
            ]
            []
        , button
            [ class "btn btn-xs btn-blue"
            , onClick SearchSubmitted
            , disabled (FieldEditor.isSubmitting editor)
            ]
            [ text "Search" ]
        ]


resultsView : Repo -> Connection SearchResult -> Html Msg
resultsView repo searchResults =
    if Connection.isEmptyAndExpanded searchResults then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "This search turned up no results!" ]

    else
        -- TODO: show list of results
        text ""
