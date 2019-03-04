module Page.WelcomeTutorial exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import Browser.Navigation as Nav
import Clipboard
import Device exposing (Device)
import Dict exposing (Dict)
import DigestSettings exposing (DigestSettings)
import Event exposing (Event)
import Flash
import Globals exposing (Globals)
import Graphics
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import KeyboardShortcuts exposing (Modifier(..))
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.MarkTutorialComplete as MarkTutorialComplete
import Mutation.UpdateTutorialStep as UpdateTutorialStep
import Nudge exposing (Nudge)
import PageError exposing (PageError)
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.Help
import Route.Posts
import Route.WelcomeTutorial exposing (Params)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, viewIf)



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id

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


stepCount : Int
stepCount =
    8



-- PAGE PROPERTIES


title : String
title =
    "How Level Works"



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( Globals, Model )
init params globals =
    let
        maybeUserId =
            Session.getUserId globals.session

        maybeSpaceId =
            globals.repo
                |> Repo.getSpaceBySlug (Route.WelcomeTutorial.getSpaceSlug params)
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
            in
            Task.succeed ( globals, model )

        _ ->
            Task.fail PageError.NotFound


setup : Globals -> Model -> Cmd Msg
setup globals model =
    Cmd.batch
        [ updateStep globals model
        , markIfComplete globals model
        , Scroll.toDocumentTop NoOp
        ]


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none


updateStep : Globals -> Model -> Cmd Msg
updateStep globals model =
    let
        variables =
            UpdateTutorialStep.variables model.spaceId "welcome" (Route.WelcomeTutorial.getStep model.params)
    in
    globals.session
        |> UpdateTutorialStep.request variables
        |> Task.attempt StepUpdated


markIfComplete : Globals -> Model -> Cmd Msg
markIfComplete globals model =
    let
        variables =
            MarkTutorialComplete.variables model.spaceId "welcome"
    in
    if Route.WelcomeTutorial.getStep model.params >= stepCount then
        globals.session
            |> MarkTutorialComplete.request variables
            |> Task.attempt MarkedComplete

    else
        Cmd.none



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | BackUp
    | Advance
    | SkipClicked
    | LinkCopied
    | LinkCopyFailed
    | StepUpdated (Result Session.Error ( Session, UpdateTutorialStep.Response ))
    | MarkedComplete (Result Session.Error ( Session, MarkTutorialComplete.Response ))
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

        BackUp ->
            backUp globals model

        Advance ->
            advance globals model

        SkipClicked ->
            let
                variables =
                    MarkTutorialComplete.variables model.spaceId "welcome"

                completeCmd =
                    globals.session
                        |> MarkTutorialComplete.request variables
                        |> Task.attempt MarkedComplete

                redirectCmd =
                    Route.pushUrl globals.navKey (redirectRoute model.params)
            in
            ( ( model, Cmd.batch [ completeCmd, redirectCmd ] ), globals )

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

        StepUpdated (Ok ( newSession, _ )) ->
            ( ( model, Cmd.none ), { globals | session = newSession } )

        StepUpdated _ ->
            ( ( model, Cmd.none ), globals )

        MarkedComplete (Ok ( newSession, _ )) ->
            ( ( model, Cmd.none ), { globals | session = newSession } )

        MarkedComplete _ ->
            ( ( model, Cmd.none ), globals )

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


backUp : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
backUp globals model =
    if Route.WelcomeTutorial.getStep model.params > 1 then
        let
            newParams =
                model.params
                    |> Route.WelcomeTutorial.setStep (Route.WelcomeTutorial.getStep model.params - 1)

            cmd =
                Route.pushUrl globals.navKey (Route.WelcomeTutorial newParams)
        in
        ( ( model, cmd ), globals )

    else
        ( ( model, Cmd.none ), globals )


advance : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
advance globals model =
    if Route.WelcomeTutorial.getStep model.params < stepCount then
        let
            newParams =
                model.params
                    |> Route.WelcomeTutorial.setStep (Route.WelcomeTutorial.getStep model.params + 1)

            cmd =
                Route.pushUrl globals.navKey (Route.WelcomeTutorial newParams)
        in
        ( ( model, cmd ), globals )

    else
        ( ( model, Cmd.none ), globals )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    ( model, Cmd.none )


consumeKeyboardEvent : Globals -> KeyboardShortcuts.Event -> Model -> ( ( Model, Cmd Msg ), Globals )
consumeKeyboardEvent globals event model =
    case ( event.key, event.modifiers ) of
        ( "ArrowLeft", [] ) ->
            backUp globals model

        ( "ArrowRight", [] ) ->
            advance globals model

        _ ->
            ( ( model, Cmd.none ), globals )



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



-- DESKTOP


resolvedDesktopView : Globals -> Model -> Data -> Html Msg
resolvedDesktopView globals model data =
    let
        step =
            Route.WelcomeTutorial.getStep model.params

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
        [ div
            [ classList
                [ ( "mx-auto leading-normal p-8 max-w-sm", True )
                ]
            ]
            [ div [ class "pb-6 text-lg text-dusty-blue-darker" ]
                [ headerView step data
                , stepView Device.Desktop step model data
                ]
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        step =
            Route.WelcomeTutorial.getStep model.params

        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = "How Level Works"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = NoOp
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.Back (Route.Help <| Route.Help.init (Route.WelcomeTutorial.getSpaceSlug model.params))
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "p-5 text-lg" ]
            [ progressBarView step
            , stepView Device.Mobile step model data
            ]
        ]



-- SHARED


headerView : Int -> Data -> Html Msg
headerView step data =
    div []
        [ h1 [ class "mb-3 font-bold tracking-semi-tight text-xl leading-tighter text-dusty-blue-darkest" ] [ text "How Level Works" ]
        , div [ class "w-32" ] [ progressBarView step ]
        ]


progressBarView : Int -> Html Msg
progressBarView step =
    let
        percentage =
            (toFloat step / toFloat stepCount)
                * 100
                |> round
                |> String.fromInt
    in
    div [ class "mb-8 rounded-full bg-grey" ]
        [ div
            [ class "h-1 rounded-full bg-turquoise"
            , style "width" (percentage ++ "%")
            , style "transition" "width 0.5s ease"
            ]
            []
        ]


stepView : Device -> Int -> Model -> Data -> Html Msg
stepView device step model data =
    case step of
        1 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ]
                    [ div [] [ text "Welcome to Level," ]
                    , div [] [ text <| SpaceUser.firstName data.viewer, text "!" ]
                    ]
                , p [ class "mb-6" ] [ text "This quick tutorial will walk you through the basic concepts. Don't worry about trying to remember everything! You can always revisit it later in the Help menu." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Let's get started" ] ]
                , button [ onClick SkipClicked, class "flex items-center text-sm text-dusty-blue no-underline" ]
                    [ span [ class "mr-2" ] [ text "Already know Level? Skip the tutorial" ]
                    ]
                ]

        2 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Channels keep messages organized." ]
                , p [ class "mb-6" ] [ text "Channels are where you go to post messages around a particular topic. When you subscribe to a Channel, its posts will appear in the timeline on your Home screen." ]
                , div []
                    [ button [ class "mr-2 btn btn-grey-outline", onClick BackUp ] [ text "Back" ]
                    , button [ class "btn btn-blue", onClick Advance ] [ text "Next" ]
                    ]
                ]

        3 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "The Inbox keeps track of your important conversations." ]
                , p [ class "mb-6" ] [ text "When someone @-mentions you or new activity occurs on a post you've interacted with, that post will move into your Inbox." ]
                , p [ class "mb-6" ] [ text "It's best to dismiss posts from your Inbox once you are finished by clicking the green ", span [ class "mx-1 inline-block" ] [ Icons.inbox Icons.On ], text " icon (or using a keyboard shortcut)." ]
                , div []
                    [ button [ class "mr-2 btn btn-grey-outline", onClick BackUp ] [ text "Back" ]
                    , button [ class "btn btn-blue", onClick Advance ] [ text "Next" ]
                    ]
                ]

        4 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "The Everything timeline helps you stay in the loop." ]
                , p [ class "mb-6" ] [ text "Your timeline contains all posts from the Channels you subscribe to. It's a good idea to periodically skim through it, but you shouldn't feel obligated to see everything there." ]
                , div []
                    [ button [ class "mr-2 btn btn-grey-outline", onClick BackUp ] [ text "Back" ]
                    , button [ class "btn btn-blue", onClick Advance ] [ text "Next" ]
                    ]
                ]

        5 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Notifications are batched to minimize distractions." ]
                , p [ class "mb-6" ] [ text "Instead of constantly interrupting you with push notifications, Level batches up your notifications and emails them to you at customizable times of the day." ]
                , p [ class "mb-6" ] [ text "Level will also send you a daily summary email to remind you what's waiting in your Inbox and summarize the latest from your Feed." ]
                , div []
                    [ button [ class "mr-2 btn btn-grey-outline", onClick BackUp ] [ text "Back" ]
                    , button [ class "btn btn-blue", onClick Advance ] [ text "Next" ]
                    ]
                ]

        6 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Who’s online? Who cares." ]
                , p [ class "mb-6" ] [ text "Just because you're signed into Level doesn't mean you're available to talk. For that reason, Level does not track who’s currently online." ]
                , div []
                    [ button [ class "mr-2 btn btn-grey-outline", onClick BackUp ] [ text "Back" ]
                    , button [ class "btn btn-blue", onClick Advance ] [ text "Next" ]
                    ]
                ]

        7 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Command the interface with your keyboard." ]
                , p [ class "mb-6" ] [ text "Power users rejoice! Level comes loaded with many of the keyboard shortcuts you already know and love. " ]
                , p [ class "mb-6" ]
                    [ text "Press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-grey font-bold" ] [ text "?" ]
                    , text " any time to see all the shortcuts."
                    ]
                , div []
                    [ button [ class "mr-2 btn btn-grey-outline", onClick BackUp ] [ text "Back" ]
                    , button [ class "btn btn-blue", onClick Advance ] [ text "Next" ]
                    ]
                ]

        8 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "We’re here to help." ]
                , p [ class "mb-6" ] [ text "To access the knowledgebase or contact support, just click Help in the left sidebar. Don’t hesitate to reach out! " ]
                , div []
                    [ button [ class "mr-2 btn btn-grey-outline", onClick BackUp ] [ text "Back" ]
                    , a [ Route.href <| redirectRoute model.params, class "btn btn-blue no-underline" ] [ text "Take me to Level" ]
                    ]
                ]

        _ ->
            text ""


redirectRoute : Params -> Route
redirectRoute params =
    Route.Posts (Route.Posts.init (Route.WelcomeTutorial.getSpaceSlug params))
