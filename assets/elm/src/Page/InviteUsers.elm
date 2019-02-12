module Page.InviteUsers exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Clipboard
import Device exposing (Device)
import Event exposing (Event)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick)
import Id exposing (Id)
import Json.Decode as Decode
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.SpaceUsers
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)



-- MODEL


type alias Model =
    { spaceSlug : String
    , viewerId : Id
    , spaceId : Id
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map2 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)



-- PAGE PROPERTIES


title : String
title =
    "Invite people"



-- LIFECYCLE


init : String -> Globals -> Task Session.Error ( Globals, Model )
init spaceSlug globals =
    globals.session
        |> SetupInit.request spaceSlug
        |> Task.map (buildModel spaceSlug globals)


buildModel : String -> Globals -> ( Session, SetupInit.Response ) -> ( Globals, Model )
buildModel spaceSlug globals ( newSession, resp ) =
    let
        model =
            Model
                spaceSlug
                resp.viewerId
                resp.spaceId

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Scroll.toDocumentTop NoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | LinkCopied
    | LinkCopyFailed
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        LinkCopied ->
            let
                newGlobals =
                    { globals | flash = Flash.set Flash.Notice "Invite link copied" 3000 globals.flash }
            in
            ( ( model, Cmd.none ), newGlobals )

        LinkCopyFailed ->
            let
                newGlobals =
                    { globals | flash = Flash.set Flash.Alert "Hmm, something went wrong" 3000 globals.flash }
            in
            ( ( model, Cmd.none ), newGlobals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


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
            , space = data.space
            , spaceUser = data.viewer
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 py-24 max-w-sm leading-normal" ]
            [ h2 [ class "mb-6 font-bold tracking-semi-tight text-3xl" ] [ text "Invite people to join" ]
            , bodyView (Space.openInvitationUrl data.space)
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "Invite people"
            , showNav = False
            , onNavToggled = NoOp
            , onSidebarToggled = NoOp
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.Back (Route.SpaceUsers (Route.SpaceUsers.init model.spaceSlug))
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "p-5" ]
            [ bodyView (Space.openInvitationUrl data.space)
            ]
        ]



-- SHARED


bodyView : Maybe String -> Html Msg
bodyView maybeUrl =
    case maybeUrl of
        Just url ->
            div []
                [ p [ class "mb-6" ] [ text "Anyone with this link can join the space with member-level permissions. You can change their role to an admin later if needed." ]
                , input [ class "mb-4 input-field font-mono text-sm", value url ] []
                , Clipboard.button "Copy link"
                    url
                    [ class "btn btn-blue"
                    , Clipboard.onCopy LinkCopied
                    , Clipboard.onCopyFailed LinkCopyFailed
                    ]
                ]

        Nothing ->
            p [ class "mb-6" ] [ text "Open invitations are disabled." ]
