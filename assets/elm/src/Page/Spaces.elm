module Page.Spaces exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import Browser.Navigation as Nav
import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import Globals exposing (Globals)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Icons
import Id exposing (Id)
import Layout.UserDesktop
import Layout.UserMobile
import PageError exposing (PageError)
import Query.SpacesInit as SpacesInit
import Repo exposing (Repo)
import Route
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import User exposing (User)



-- MODEL


type alias Model =
    { viewerId : Id
    , query : String

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : User
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map Data
        (Repo.getUser model.viewerId repo)



-- PAGE PROPERTIES


title : String
title =
    "Teams"



-- LIFECYCLE


init : Globals -> Task PageError ( Globals, Model )
init globals =
    case Session.getUserId globals.session of
        Just viewerId ->
            let
                model =
                    Model
                        viewerId
                        ""
                        False
                        False
            in
            Task.succeed ( globals, model )

        _ ->
            Task.fail PageError.NotFound


setup : Model -> Cmd Msg
setup model =
    Scroll.toDocumentTop NoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = QueryChanged String
    | NoOp
    | ToggleKeyboardCommands
    | ToggleNotifications
    | InternalLinkClicked String
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        QueryChanged val ->
            ( ( { model | query = val }, Cmd.none ), globals )

        NoOp ->
            ( ( model, Cmd.none ), globals )

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        ToggleNotifications ->
            ( ( model, Cmd.none ), { globals | showNotifications = not globals.showNotifications } )

        InternalLinkClicked pathname ->
            ( ( model, Nav.pushUrl globals.navKey pathname ), globals )

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.none



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


resolvedDesktopView : Globals -> Model -> Data -> Html Msg
resolvedDesktopView globals model data =
    let
        config =
            { globals = globals
            , viewer = data.viewer
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            , onPageClicked = NoOp
            }

        spaces =
            globals.repo
                |> Repo.getAllSpaces
                |> List.sortBy Space.name
    in
    Layout.UserDesktop.layout config
        [ div [ class "mx-auto px-4 py-8 max-w-sm" ]
            [ div [ class "flex items-center pb-6" ]
                [ h1 [ class "flex-1 ml-4 mr-4 font-bold tracking-semi-tight text-3xl" ] [ text "My Teams" ]
                , div [ class "flex-0 flex-no-shrink" ]
                    [ a [ Route.href Route.NewSpace, class "btn btn-blue btn-md no-underline" ]
                        [ text "Create a team" ]
                    ]
                ]
            , div [ class "pb-6" ]
                [ label [ class "flex items-center p-4 w-full rounded bg-grey-light" ]
                    [ div [ class "flex-0 flex-no-shrink pr-3" ] [ Icons.search ]
                    , input
                        [ id "search-input"
                        , type_ "text"
                        , class "flex-1 bg-transparent no-outline"
                        , placeholder "Type to search"
                        , onInput QueryChanged
                        ]
                        []
                    ]
                ]
            , div [ class "mx-4" ]
                [ spacesView globals.repo model.query spaces ]
            ]
        ]


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , viewer = data.viewer
            , title = "My Teams"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.UserMobile.NoControl
            , rightControl =
                Layout.UserMobile.Custom <|
                    a
                        [ Route.href Route.NewSpace
                        , class "btn btn-blue btn-md no-underline"
                        ]
                        [ text "New" ]
            }

        spaces =
            globals.repo
                |> Repo.getAllSpaces
                |> List.sortBy Space.name
    in
    Layout.UserMobile.layout config
        [ div [ class "p-3" ]
            [ spacesView globals.repo model.query spaces ]
        ]


spacesView : Repo -> String -> List Space -> Html Msg
spacesView repo query spaces =
    if List.isEmpty spaces then
        blankSlateView

    else
        let
            filteredSpaces =
                filter query spaces
        in
        if List.isEmpty filteredSpaces then
            div [ class "py-2 text-base" ] [ text "No teams match your search." ]

        else
            div [] <|
                List.map (spaceView query) filteredSpaces


blankSlateView : Html Msg
blankSlateView =
    div [ class "py-2 text-center text-lg" ] [ text "You aren't a member of any teams yet!" ]


spaceView : String -> Space -> Html Msg
spaceView query space =
    a [ href ("/" ++ Space.slug space ++ "/"), class "flex items-center pr-4 pb-1 no-underline text-blue" ]
        [ div [ class "mr-3" ] [ Space.avatar Avatar.Small space ]
        , h2 [ class "font-normal font-sans text-lg" ] [ text <| Space.name space ]
        ]


filter : String -> List Space -> List Space
filter query spaces =
    let
        doesMatch space =
            space
                |> Space.name
                |> String.toLower
                |> String.contains (String.toLower query)
    in
    List.filter doesMatch spaces
