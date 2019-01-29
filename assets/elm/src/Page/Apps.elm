module Page.Apps exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

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
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Apps exposing (Params)
import Route.WelcomeTutorial
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, viewIf)



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
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


title : String
title =
    "Help"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SetupInit.request (Route.Apps.getSpaceSlug params)
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SetupInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
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
    | LinkCopied
    | LinkCopyFailed
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

        LinkCopied ->
            let
                newGlobals =
                    { globals | flash = Flash.set Flash.Notice "URL copied" 3000 globals.flash }
            in
            ( ( model, Cmd.none ), newGlobals )

        LinkCopyFailed ->
            let
                newGlobals =
                    { globals | flash = Flash.set Flash.Alert "Hmm, something went wrong" 3000 globals.flash }
            in
            ( ( model, Cmd.none ), newGlobals )

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
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        _ ->
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
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , showKeyboardCommands = globals.showKeyboardCommands
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto max-w-md leading-normal p-8" ]
            [ div [ class "pb-6 text-dusty-blue-darker" ]
                [ div [ class "mb-6" ]
                    [ h1 [ class "mb-4 font-bold tracking-semi-tight text-3xl text-dusty-blue-darkest" ] [ text "Integrations" ]
                    , p [ class "mb-6 pb-4 border-b text-lg" ] [ text "Get other apps or your own code talking to Level." ]
                    , ul [ class "list-reset " ]
                        [ li []
                            [ div [ class "flex mb-6" ]
                                [ div [ class "mr-3 flex-no-grow" ] [ Icons.postbot ]
                                , div [ class "flex-grow" ]
                                    [ h2 [ class "text-xl tracking-semi-tight" ] [ text "Postbot" ]
                                    , p [] [ text "Send messages to Level with a simple HTTP call." ]
                                    ]
                                ]
                            , p [ class "mb-6" ] [ text "The request body must contain a JSON object with a ", code [ class "px-1 bg-grey rounded" ] [ text "body" ], text " attribute and a ", code [ class "px-1 bg-grey rounded" ] [ text "display_name" ], text " attribute (which will be used in place of the author label on the post). The ", code [ class "px-1 bg-grey rounded" ] [ text "body" ], text " must include a #channel reference or an @-mention—otherwise the message would not be visible to anyone!" ]
                            , p [ class "mb-3" ] [ text "Here's the URL for posting messages to this team:" ]
                            , div [ class "mb-6 flex items-baseline input-field p-0 pr-3 bg-grey border-none" ]
                                [ input [ type_ "text", class "block mr-4 pl-3 py-1 bg-transparent flex-grow font-mono text-base overflow-auto text-dusty-blue-darker", value (Space.postbotUrl data.space), readonly True ] []
                                , Clipboard.button "Copy"
                                    (Space.postbotUrl data.space)
                                    [ class "btn btn-blue btn-xs flex items-center"
                                    , Clipboard.onCopy LinkCopied
                                    , Clipboard.onCopyFailed LinkCopyFailed
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "Apps"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "p-4 leading-normal" ]
            [ div [ class "pb-6 text-dusty-blue-darker" ]
                []
            ]
        ]
