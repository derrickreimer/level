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
import PageError exposing (PageError)
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

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
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
    "Integrations"



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( Globals, Model )
init params globals =
    let
        maybeUserId =
            Session.getUserId globals.session

        maybeSpaceId =
            globals.repo
                |> Repo.getSpaceBySlug (Route.Apps.getSpaceSlug params)
                |> Maybe.andThen (Just << Space.id)

        maybeViewerId =
            case ( maybeSpaceId, maybeUserId ) of
                ( Just spaceId, Just userId ) ->
                    Repo.getSpaceUserByUserId spaceId userId globals.repo
                        |> Maybe.andThen (Just << SpaceUser.id)

                _ ->
                    Nothing
    in
    case ( maybeViewerId, maybeSpaceId ) of
        ( Just viewerId, Just spaceId ) ->
            let
                model =
                    Model
                        params
                        viewerId
                        spaceId
                        False
                        False
            in
            Task.succeed ( globals, model )

        _ ->
            Task.fail PageError.NotFound


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
    | ToggleNotifications
    | InternalLinkClicked String
    | OpenBeacon
    | TextCopied String
    | TextCopyFailed
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

        ToggleNotifications ->
            ( ( model, Cmd.none ), { globals | showNotifications = not globals.showNotifications } )

        InternalLinkClicked pathname ->
            ( ( model, Nav.pushUrl globals.navKey pathname ), globals )

        OpenBeacon ->
            ( ( model, Beacon.open ), globals )

        TextCopied flash ->
            let
                newGlobals =
                    { globals | flash = Flash.set Flash.Notice flash 3000 globals.flash }
            in
            ( ( model, Cmd.none ), newGlobals )

        TextCopyFailed ->
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
            , onPageClicked = NoOp
            , onToggleNotifications = ToggleNotifications
            , onInternalLinkClicked = InternalLinkClicked
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto max-w-md leading-normal p-8" ]
            [ div [ class "pb-6 text-dusty-blue-darker" ]
                [ div [ class "mb-6" ]
                    [ h1 [ class "mb-4 font-bold tracking-semi-tight text-3xl text-dusty-blue-darkest" ] [ text "Integrations" ]
                    , p [ class "mb-6 pb-4 border-b text-base" ] [ text "Get other apps talking to Level." ]
                    , ul [ class "list-reset " ]
                        [ li []
                            [ postbotInstructions data
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
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = "Integrations"
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
        [ div [ class "p-4" ]
            [ div [ class "pb-6 text-dusty-blue-darker" ]
                [ ul [ class "list-reset" ]
                    [ li []
                        [ postbotInstructions data
                        ]
                    ]
                ]
            ]
        ]



-- SHARED


postbotInstructions : Data -> Html Msg
postbotInstructions data =
    let
        curlCommand =
            buildPostbotCommand (Space.postbotUrl data.space) (SpaceUser.handle data.viewer)
    in
    div [ class "flex mb-6" ]
        [ div [ class "mr-3 flex-no-grow" ] [ Icons.postbot ]
        , div [ class "flex-grow" ]
            [ h2 [ class "text-xl tracking-semi-tight" ] [ text "Postbot" ]
            , p [ class "mb-6" ] [ text "Send messages to Level with a simple HTTP call." ]
            , h2 [ class "mb-2 text-lg font-bold" ] [ text "Endpoint" ]
            , p [ class "mb-3" ] [ text "Use the POST method with a JSON content type." ]
            , div [ class "mb-6 flex items-baseline input-field p-0 pr-3 bg-grey-light border-none" ]
                [ input [ type_ "text", class "block mr-4 pl-3 py-1 bg-transparent flex-grow font-mono text-md overflow-auto text-dusty-blue-darker", value (Space.postbotUrl data.space), readonly True ] []
                , Clipboard.button "Copy"
                    (Space.postbotUrl data.space)
                    [ class "btn btn-blue btn-xs flex items-center"
                    , Clipboard.onCopy (TextCopied "URL copied")
                    , Clipboard.onCopyFailed TextCopyFailed
                    ]
                ]
            , h2 [ class "mb-2 text-lg font-bold" ] [ text "Payload" ]
            , p [ class "mb-3" ] [ text "The endpoint expects a JSON payload with the following values:" ]
            , table [ class "mb-6 table-collapse text-left border rounded w-full" ]
                [ tr [ class "m-0" ]
                    [ th [ class "p-2 bg-grey-light border-b text-dusty-blue" ] [ text "Key" ]
                    , th [ class "p-2 bg-grey-light border-b text-dusty-blue" ] [ text "Value" ]
                    ]
                , tr [ class "border-b" ]
                    [ td [ class "p-2" ] [ code [ class "px-1 bg-grey rounded" ] [ text "body" ] ]
                    , td [ class "p-2" ] [ text "The Markdown-formatted message body (must include a #channel or @person)" ]
                    ]
                , tr []
                    [ td [ class "p-2" ] [ code [ class "px-1 bg-grey rounded" ] [ text "display_name" ] ]
                    , td [ class "p-2" ] [ text "The name to display as the author of the post" ]
                    ]
                ]
            , h2 [ class "mb-2 text-lg font-bold" ] [ text "Example Request" ]
            , p [ class "mb-3" ] [ text "Paste the following into your Terminal to send yourself a bot message." ]
            , div [ class "mb-6 flex items-start input-field p-0 pr-3 bg-grey-light border-none" ]
                [ textarea [ class "block flex-grow mr-4 pl-3 py-2 h-16 bg-transparent font-mono text-md text-dusty-blue-darker resize-none whitespace-pre overflow-scroll", readonly True, style "overflow-wrap" "normal" ]
                    [ text curlCommand ]
                , div [ class "py-2" ]
                    [ Clipboard.button "Copy"
                        curlCommand
                        [ class "btn btn-blue btn-xs flex items-center"
                        , Clipboard.onCopy (TextCopied "cURL command copied")
                        , Clipboard.onCopyFailed TextCopyFailed
                        ]
                    ]
                ]
            ]
        ]


buildPostbotCommand : String -> String -> String
buildPostbotCommand url handle =
    let
        lines =
            [ "curl -X POST " ++ url ++ " \\"
            , "  -H \"Content-Type: application/json\" \\"
            , "  -d '{\"body\": \"Hello @" ++ handle ++ "!\", \"display_name\": \"Postbot\"}'"
            ]
    in
    String.join "\n" lines
