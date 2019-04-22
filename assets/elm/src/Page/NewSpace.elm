module Page.NewSpace exposing (Model, Msg(..), consumeEvent, init, setup, slugify, subscriptions, teardown, title, update, view)

import Avatar
import Beacon
import Browser.Navigation as Nav
import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import Globals exposing (Globals)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onBlur, onClick, onInput)
import Id exposing (Id)
import Layout.UserDesktop
import Layout.UserMobile
import Mutation.CreateSpace as CreateSpace
import PageError exposing (PageError)
import Query.Viewer as Viewer
import Regex exposing (Regex)
import Repo exposing (Repo)
import Route
import Route.WelcomeTutorial
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import User exposing (User)
import ValidationError exposing (ValidationError, errorView, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)



-- MODEL


type alias Model =
    { viewerId : Id
    , name : String
    , slug : String
    , errors : List ValidationError
    , formState : FormState

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type FormState
    = Idle
    | Submitting


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
    "Create a team"



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
                        ""
                        []
                        Idle
                        False
                        False
            in
            Task.succeed ( globals, model )

        _ ->
            Task.fail PageError.NotFound


setup : Model -> Cmd Msg
setup model =
    Cmd.batch
        [ Scroll.toDocumentTop NoOp
        , Beacon.init
        ]


teardown : Model -> Cmd Msg
teardown model =
    Beacon.destroy



-- UPDATE


type Msg
    = NameChanged String
    | SlugChanged String
    | Submit
    | Submitted (Result Session.Error ( Session, CreateSpace.Response ))
    | NoOp
    | ToggleKeyboardCommands
    | ToggleNotifications
    | InternalLinkClicked String
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Nav.Key -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals navKey model =
    case msg of
        NameChanged val ->
            ( ( { model | name = val, slug = slugify val }, Cmd.none ), globals )

        SlugChanged val ->
            ( ( { model | slug = val }, Cmd.none ), globals )

        Submit ->
            let
                cmd =
                    globals.session
                        |> CreateSpace.request model.name model.slug
                        |> Task.attempt Submitted
            in
            ( ( { model | formState = Submitting }, cmd ), globals )

        Submitted (Ok ( newSession, CreateSpace.Success space )) ->
            let
                tutorialParams =
                    Route.WelcomeTutorial.init (Space.slug space) 1
            in
            ( ( model, Route.pushUrl navKey (Route.WelcomeTutorial tutorialParams) )
            , { globals | session = newSession }
            )

        Submitted (Ok ( newSession, CreateSpace.Invalid errors )) ->
            ( ( { model | errors = errors, formState = Idle }, Cmd.none )
            , { globals | session = newSession }
            )

        Submitted (Err _) ->
            ( ( { model | formState = Idle }, Cmd.none ), globals )

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


specialCharRegex : Regex
specialCharRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "[^a-z0-9]+"


paddedDashRegex : Regex
paddedDashRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "(^-|-$)"


slugify : String -> String
slugify name =
    name
        |> String.toLower
        |> Regex.replace specialCharRegex (\_ -> "-")
        |> Regex.replace paddedDashRegex (\_ -> "")
        |> String.slice 0 20



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.none



-- VIEW


type alias FormField =
    { type_ : String
    , name : String
    , placeholder : String
    , value : String
    , onInput : String -> Msg
    , autofocus : Bool
    }


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
    in
    Layout.UserDesktop.layout config
        [ div
            [ classList
                [ ( "mx-auto max-w-xs leading-normal py-24", True )
                , ( "shake", not (List.isEmpty model.errors) )
                ]
            ]
            [ div [ class "pb-6" ]
                [ h1 [ class "pb-4 font-bold tracking-semi-tight text-3xl" ] [ text "Create a team" ]
                , p [] [ text "Try Level free for 30 days. Once you create your team, you can invite your teammates to join you!" ]
                ]
            , formFields model
            , button
                [ type_ "submit"
                , class "btn btn-blue"
                , onClick Submit
                , disabled (model.formState == Submitting)
                ]
                [ text "Create my team" ]
            ]
        ]


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , viewer = data.viewer
            , title = "New Team"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.UserMobile.Back Route.Spaces
            , rightControl =
                Layout.UserMobile.Custom <|
                    button
                        [ type_ "submit"
                        , class "btn btn-blue btn-md"
                        , onClick Submit
                        , disabled (model.formState == Submitting)
                        ]
                        [ text "Create" ]
            }
    in
    Layout.UserMobile.layout config
        [ div
            [ classList
                [ ( "p-5", True )
                , ( "shake", not (List.isEmpty model.errors) )
                ]
            ]
            [ div [ class "pb-6" ]
                [ p [] [ text "Try Level free for 30 days. Once you create your team, you can invite your teammates to join you!" ]
                ]
            , formFields model
            ]
        ]



-- SHARED


formFields : Model -> Html Msg
formFields model =
    div []
        [ div [ class "pb-6" ]
            [ label [ for "name", class "input-label" ] [ text "Name your team" ]
            , textField (FormField "text" "name" "Smith, Co." model.name NameChanged True) model.errors
            ]
        , div [ class "pb-6" ]
            [ label [ for "slug", class "input-label" ] [ text "Pick your URL" ]
            , slugField model.slug model.errors
            ]
        ]


textField : FormField -> List ValidationError -> Html Msg
textField field errors =
    let
        classes =
            [ ( "input-field w-full", True )
            , ( "input-field-error", isInvalid field.name errors )
            ]
    in
    div []
        [ input
            [ id field.name
            , type_ field.type_
            , classList classes
            , name field.name
            , placeholder field.placeholder
            , value field.value
            , onInput field.onInput
            , autofocus field.autofocus
            , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
            ]
            []
        , errorView field.name errors
        ]


slugField : String -> List ValidationError -> Html Msg
slugField slug errors =
    let
        classes =
            [ ( "input-field inline-flex leading-none items-baseline", True )
            , ( "input-field-error", isInvalid "slug" errors )
            ]
    in
    div []
        [ div [ classList classes ]
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
                    , value slug
                    , onInput SlugChanged
                    , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                    ]
                    []
                ]
            ]
        , errorView "slug" errors
        ]
