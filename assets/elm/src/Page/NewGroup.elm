module Page.NewGroup exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Browser.Navigation as Nav
import Device exposing (Device)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Id exposing (Id)
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CreateGroup as CreateGroup
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.Groups
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
    { spaceSlug : String
    , viewerId : Id
    , spaceId : Id
    , name : String
    , isDefault : Bool
    , isSubmitting : Bool
    , errors : List ValidationError

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
    "Create a channel"



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
                ""
                False
                False
                []
                False
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.batch
        [ setFocus "name" NoOp
        , Scroll.toDocumentTop NoOp
        ]


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | NameChanged String
    | DefaultToggled
    | Submit
    | Submitted (Result Session.Error ( Session, CreateGroup.Response ))
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Nav.Key -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals navKey model =
    case msg of
        NoOp ->
            noCmd globals model

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        NameChanged val ->
            let
                newName =
                    val
                        |> String.toLower
                        |> String.replace " " "-"
            in
            noCmd globals { model | name = newName }

        Submit ->
            let
                cmd =
                    globals.session
                        |> CreateGroup.request model.spaceId model.name model.isDefault
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True }, cmd ), globals )

        Submitted (Ok ( newSession, CreateGroup.Success group )) ->
            let
                redirectTo =
                    Route.Group (Route.Group.init model.spaceSlug (Group.name group))
            in
            ( ( model, Route.pushUrl navKey redirectTo ), { globals | session = newSession } )

        Submitted (Ok ( newSession, CreateGroup.Invalid errors )) ->
            ( ( { model | isSubmitting = False, errors = errors }, Cmd.none )
            , { globals | session = newSession }
            )

        Submitted (Err Session.Expired) ->
            redirectToLogin globals model

        Submitted (Err _) ->
            noCmd globals model

        DefaultToggled ->
            noCmd globals { model | isDefault = not model.isDefault }

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
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "pb-6" ]
                [ h1 [ class "pb-4 font-bold tracking-semi-tight text-3xl" ] [ text "Create a channel" ]
                , p [] [ text subheading ]
                ]
            , fieldsView model
            , button
                [ type_ "submit"
                , class "btn btn-blue"
                , onClick Submit
                , disabled model.isSubmitting
                ]
                [ text "Create channel" ]
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
            , title = "Create a channel"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.Back (Route.Groups <| Route.Groups.init model.spaceSlug)
            , rightControl =
                Layout.SpaceMobile.Custom <|
                    button
                        [ class "btn btn-blue btn-md no-underline"
                        , onClick Submit
                        , disabled model.isSubmitting
                        ]
                        [ text "Save" ]
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "p-5" ]
            [ p [ class "pb-6" ] [ text subheading ]
            , fieldsView model
            ]
        ]



-- SHARED


subheading : String
subheading =
    "Channels can be used to categorize anything, such as teams within your organization or projects you are working on."


fieldsView : Model -> Html Msg
fieldsView model =
    div []
        [ div [ class "pb-6" ]
            [ label [ for "name", class "input-label" ] [ text "Name the channel" ]
            , div
                [ classList
                    [ ( "input-field inline-flex leading-none items-baseline", True )
                    , ( "input-field-error", isInvalid "name" model.errors )
                    ]
                ]
                [ label
                    [ for "name"
                    , class "mr-1 flex-none text-dusty-blue-dark select-none font-bold"
                    ]
                    [ text "#" ]
                , div [ class "flex-1" ]
                    [ input
                        [ id "handle"
                        , type_ "text"
                        , class "placeholder-blue w-full p-0 no-outline text-dusty-blue-darker"
                        , name "name"
                        , placeholder "my-new-channel"
                        , value model.name
                        , onInput NameChanged
                        , onKeydown preventDefault [ ( [], enter, \_ -> Submit ) ]
                        , disabled model.isSubmitting
                        ]
                        []
                    ]
                ]
            , errorView "name" model.errors
            ]
        , label [ class "control checkbox pb-6" ]
            [ input
                [ type_ "checkbox"
                , class "checkbox"
                , onClick DefaultToggled
                , checked model.isDefault
                ]
                []
            , span [ class "control-indicator" ] []
            , span [ class "select-none" ] [ text "Auto-subscribe new members to this channel" ]
            ]
        ]
