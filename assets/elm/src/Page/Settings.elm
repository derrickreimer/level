module Page.Settings exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import Browser.Navigation as Nav
import Device exposing (Device)
import DigestSettings exposing (DigestSettings)
import Event exposing (Event)
import File exposing (File)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Id exposing (Id)
import Json.Decode as Decode
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Minutes
import Mutation.CreateNudge as CreateNudge
import Mutation.DeleteNudge as DeleteNudge
import Mutation.UpdateDigestSettings as UpdateDigestSettings
import Mutation.UpdateSpace as UpdateSpace
import Mutation.UpdateSpaceAvatar as UpdateSpaceAvatar
import Nudge exposing (Nudge)
import Query.SettingsInit as SettingsInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Settings exposing (Params)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, errorsNotFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (viewIf)
import View.Nudges



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , name : String
    , slug : String
    , digestSettings : DigestSettings
    , nudges : List Nudge
    , timeZone : String
    , avatarUrl : Maybe String
    , errors : List ValidationError
    , isSubmitting : Bool
    , newAvatar : Maybe File

    -- MOBILE
    , showNav : Bool
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
    "Settings"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SettingsInit.request (Route.Settings.getSpaceSlug params)
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SettingsInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                (Space.name resp.space)
                (Space.slug resp.space)
                resp.digestSettings
                resp.nudges
                resp.timeZone
                (Space.avatarUrl resp.space)
                []
                False
                Nothing
                False

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
    | ToggleNotifications
    | InternalLinkClicked String
    | NameChanged String
    | SlugChanged String
    | Submit
    | Submitted (Result Session.Error ( Session, UpdateSpace.Response ))
    | AvatarSubmitted (Result Session.Error ( Session, UpdateSpaceAvatar.Response ))
    | AvatarSelected
    | FileReceived Decode.Value
    | DigestToggled
    | DigestSettingsUpdated (Result Session.Error ( Session, UpdateDigestSettings.Response ))
    | NudgeToggled Int
    | NudgeCreated (Result Session.Error ( Session, CreateNudge.Response ))
    | NudgeDeleted (Result Session.Error ( Session, DeleteNudge.Response ))
      -- MOBILE
    | NavToggled
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

        NameChanged val ->
            noCmd globals { model | name = val }

        SlugChanged val ->
            noCmd globals { model | slug = val }

        Submit ->
            let
                cmd =
                    globals.session
                        |> UpdateSpace.request model.spaceId model.name model.slug
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True, errors = [] }, cmd ), globals )

        Submitted (Ok ( newSession, UpdateSpace.Success space )) ->
            let
                newGlobals =
                    { globals
                        | session = newSession
                        , flash = Flash.set Flash.Notice "Settings saved" 3000 globals.flash
                    }
            in
            noCmd newGlobals
                { model
                    | name = Space.name space
                    , slug = Space.slug space
                    , isSubmitting = False
                }

        Submitted (Ok ( newSession, UpdateSpace.Invalid errors )) ->
            noCmd { globals | session = newSession } { model | isSubmitting = False, errors = errors }

        Submitted (Err Session.Expired) ->
            redirectToLogin globals model

        Submitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd globals { model | isSubmitting = False }

        AvatarSelected ->
            ( ( model, File.request "avatar" ), globals )

        FileReceived value ->
            case Decode.decodeValue File.decoder value of
                Ok file ->
                    let
                        cmd =
                            case File.getContents file of
                                Just contents ->
                                    globals.session
                                        |> UpdateSpaceAvatar.request model.spaceId contents
                                        |> Task.attempt AvatarSubmitted

                                Nothing ->
                                    Cmd.none
                    in
                    ( ( { model | newAvatar = Just file }, cmd ), globals )

                _ ->
                    noCmd globals model

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Success space )) ->
            noCmd { globals | session = newSession } { model | avatarUrl = Space.avatarUrl space }

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Invalid errors )) ->
            noCmd { globals | session = newSession } { model | errors = errors }

        AvatarSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        AvatarSubmitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd globals { model | isSubmitting = False }

        DigestToggled ->
            let
                cmd =
                    globals.session
                        |> UpdateDigestSettings.request model.spaceId (not (DigestSettings.isEnabled model.digestSettings))
                        |> Task.attempt DigestSettingsUpdated
            in
            ( ( { model | digestSettings = DigestSettings.toggle model.digestSettings }, cmd ), globals )

        DigestSettingsUpdated (Ok ( newSession, UpdateDigestSettings.Success newDigestSettings )) ->
            ( ( { model | digestSettings = newDigestSettings, isSubmitting = False }
              , Cmd.none
              )
            , { globals
                | session = newSession
                , flash = Flash.set Flash.Notice "Digest updated" 3000 globals.flash
              }
            )

        DigestSettingsUpdated (Err Session.Expired) ->
            redirectToLogin globals model

        DigestSettingsUpdated _ ->
            -- TODO: handle unexpected exceptions
            noCmd globals { model | isSubmitting = False }

        NudgeToggled minute ->
            let
                cmd =
                    case nudgeAt minute model of
                        Just nudge ->
                            globals.session
                                |> DeleteNudge.request (DeleteNudge.variables model.spaceId (Nudge.id nudge))
                                |> Task.attempt NudgeDeleted

                        Nothing ->
                            globals.session
                                |> CreateNudge.request (CreateNudge.variables model.spaceId minute)
                                |> Task.attempt NudgeCreated
            in
            ( ( model, cmd ), globals )

        NudgeCreated (Ok ( newSession, CreateNudge.Success nudge )) ->
            let
                newNudges =
                    nudge :: model.nudges
            in
            ( ( { model | nudges = newNudges }, Cmd.none )
            , { globals | session = newSession }
            )

        NudgeCreated (Err Session.Expired) ->
            redirectToLogin globals model

        NudgeCreated _ ->
            noCmd globals model

        NudgeDeleted (Ok ( newSession, DeleteNudge.Success nudge )) ->
            let
                newNudges =
                    removeBy Nudge.id nudge model.nudges
            in
            ( ( { model | nudges = newNudges }, Cmd.none )
            , { globals | session = newSession }
            )

        NudgeDeleted (Err Session.Expired) ->
            redirectToLogin globals model

        NudgeDeleted _ ->
            noCmd globals model

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

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
    File.receive FileReceived



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
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto max-w-md leading-normal p-8" ]
            [ div [ class "pb-4" ]
                [ h1 [ class "font-bold tracking-semi-tight text-3xl" ] [ text "Settings" ]
                ]
            , div [ class "flex items-baseline mb-6 border-b" ]
                [ filterTab Device.Desktop "Preferences" Route.Settings.Preferences (Route.Settings.setSection Route.Settings.Preferences model.params) model.params
                , viewIf (Space.canUpdate data.space) <|
                    filterTab Device.Desktop "Team Settings" Route.Settings.Space (Route.Settings.setSection Route.Settings.Space model.params) model.params
                ]
            , viewIf (Route.Settings.getSection model.params == Route.Settings.Preferences) <|
                preferencesView Device.Desktop model data
            , viewIf (Route.Settings.getSection model.params == Route.Settings.Space) <|
                spaceSettingsView model data
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
            , title = "Settings"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = NoOp
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "flex justify-center items-baseline mb-2 pt-2 border-b" ]
            [ filterTab Device.Mobile "Preferences" Route.Settings.Preferences (Route.Settings.setSection Route.Settings.Preferences model.params) model.params
            , viewIf (Space.canUpdate data.space) <|
                filterTab Device.Mobile "Team Settings" Route.Settings.Space (Route.Settings.setSection Route.Settings.Space model.params) model.params
            ]
        , div [ class "p-5" ]
            [ viewIf (Route.Settings.getSection model.params == Route.Settings.Preferences) <|
                preferencesView Device.Mobile model data
            , viewIf (Route.Settings.getSection model.params == Route.Settings.Space) <|
                spaceSettingsView model data
            ]
        ]



-- SHARED


preferencesView : Device -> Model -> Data -> Html Msg
preferencesView device model data =
    div []
        [ nudgesView device model data
        , digestsView model data
        ]


nudgesView : Device -> Model -> Data -> Html Msg
nudgesView device model data =
    let
        config =
            View.Nudges.Config NudgeToggled model.nudges model.timeZone
    in
    div [ class "mb-8" ]
        [ h2 [ class "mb-2 text-dusty-blue-darker text-xl font-bold" ] [ text "Batched Notifications" ]
        , p [ class "mb-4" ] [ text "Configure the times of day when Level should notify you about new Inbox activity." ]
        , viewIf (device == Device.Desktop) (View.Nudges.desktopView config)
        , viewIf (device == Device.Mobile) (View.Nudges.mobileView config)
        ]


digestsView : Model -> Data -> Html Msg
digestsView model data =
    div []
        [ h2 [ class "mb-2 text-dusty-blue-darker text-xl font-bold" ] [ text "Daily Summary" ]
        , p [ class "mb-6" ] [ text "This email reminds you what's in your Inbox and summarizes recent activity in the channels you follow." ]
        , label [ class "control checkbox pb-6" ]
            [ input
                [ type_ "checkbox"
                , class "checkbox"
                , onClick DigestToggled
                , checked (DigestSettings.isEnabled model.digestSettings)
                , disabled model.isSubmitting
                ]
                []
            , span [ class "control-indicator" ] []
            , span [ class "select-none text-dusty-blue-dark" ] [ text "Email me a daily summary" ]
            ]
        ]


spaceSettingsView : Model -> Data -> Html Msg
spaceSettingsView model data =
    div []
        [ div [ class "pb-6" ]
            [ label [ for "name", class "input-label" ] [ text "Team Name" ]
            , input
                [ id "name"
                , type_ "text"
                , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "name" model.errors ) ]
                , name "name"
                , placeholder "Acme, Co."
                , value model.name
                , onInput NameChanged
                , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                , disabled model.isSubmitting
                ]
                []
            , errorView "name" model.errors
            ]
        , div [ class "pb-6" ]
            [ label [ for "slug", class "input-label" ] [ text "URL" ]
            , div
                [ classList
                    [ ( "input-field inline-flex leading-none items-baseline", True )
                    , ( "input-field-error", isInvalid "slug" model.errors )
                    ]
                ]
                [ label
                    [ for "slug"
                    , class "flex-none text-dusty-blue-darker select-none"
                    ]
                    [ text "level.app/" ]
                , div [ class "flex-1" ]
                    [ input
                        [ id "slug"
                        , type_ "text"
                        , class "placeholder-blue w-full p-0 no-outline text-dusty-blue-darker"
                        , name "slug"
                        , placeholder "smith-co"
                        , value model.slug
                        , onInput SlugChanged
                        , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                        , disabled model.isSubmitting
                        ]
                        []
                    ]
                ]
            , errorView "slug" model.errors
            ]
        , div [ class "pb-6" ]
            [ label [ for "avatar", class "input-label" ] [ text "Team Logo" ]
            , Avatar.uploader "avatar" model.avatarUrl AvatarSelected
            ]
        , button
            [ type_ "submit"
            , class "btn btn-blue"
            , onClick Submit
            , disabled model.isSubmitting
            ]
            [ text "Save settings" ]
        ]


filterTab : Device -> String -> Route.Settings.Section -> Params -> Params -> Html Msg
filterTab device label section linkParams currentParams =
    let
        isCurrent =
            Route.Settings.getSection currentParams == section
    in
    a
        [ Route.href (Route.Settings linkParams)
        , classList
            [ ( "block text-md py-3 px-4 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue-dark", not isCurrent )
            , ( "border-blue text-blue", isCurrent )
            , ( "text-center min-w-100px", device == Device.Mobile )
            ]
        ]
        [ text label ]



-- HELPERS


nudgeAt : Int -> Model -> Maybe Nudge
nudgeAt minute model =
    model.nudges
        |> List.filter (\nudge -> Nudge.minute nudge == minute)
        |> List.head
