module Page.Home exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Beacon
import Browser.Navigation as Nav
import Clipboard
import Device exposing (Device)
import Event exposing (Event)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Layout.UserDesktop
import Layout.UserMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Query.Viewer as Viewer
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Help exposing (Params)
import Route.WelcomeTutorial
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import User exposing (User)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, viewIf)



-- MODEL


type alias Model =
    { viewerId : Id

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
    "Home"



-- LIFECYCLE


init : Globals -> Task Session.Error ( Globals, Model )
init globals =
    globals.session
        |> Viewer.request
        |> Task.map (buildModel globals)


buildModel : Globals -> ( Session, Viewer.Response ) -> ( Globals, Model )
buildModel globals ( newSession, resp ) =
    let
        model =
            Model
                resp.viewerId
                False
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Beacon.init


teardown : Model -> Cmd Msg
teardown model =
    Beacon.destroy



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | OpenBeacon
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        OpenBeacon ->
            ( ( model, Beacon.open ), globals )

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
            , viewer = data.viewer
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.UserDesktop.layout config
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "pb-6 text-dusty-blue-darker" ]
                [ div [ class "mb-6" ]
                    [ h1 [ class "mb-4 font-bold tracking-semi-tight text-3xl text-dusty-blue-darkest" ] [ text "Home" ]
                    ]
                ]
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , viewer = data.viewer
            , title = "Home"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.UserMobile.NoControl
            , rightControl = Layout.UserMobile.NoControl
            }
    in
    Layout.UserMobile.layout config
        [ div [ class "p-5" ]
            [ div [ class "pb-6 text-dusty-blue-darker" ]
                []
            ]
        ]
