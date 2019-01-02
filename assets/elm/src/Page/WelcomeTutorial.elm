module Page.WelcomeTutorial exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, setup, subscriptions, teardown, title, update, view)

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
import Mutation.BulkCreateGroups as BulkCreateGroups
import Mutation.CreateGroup as CreateGroup
import Mutation.CreateNudge as CreateNudge
import Mutation.DeleteNudge as DeleteNudge
import Mutation.MarkTutorialComplete as MarkTutorialComplete
import Mutation.UpdateTutorialStep as UpdateTutorialStep
import Nudge exposing (Nudge)
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.Help
import Route.Inbox
import Route.WelcomeTutorial exposing (Params)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, viewIf)
import View.Nudges



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , selectedGroups : List String
    , digestSettings : DigestSettings
    , nudges : List Nudge
    , timeZone : String
    , isSubmitting : Bool
    , keyboardTutorialStep : Int

    -- MOBILE
    , showNav : Bool
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


defaultGroups : List String
defaultGroups =
    [ "Everyone", "Engineering", "Marketing", "Support", "Random" ]


stepCount : Int
stepCount =
    8



-- PAGE PROPERTIES


title : String
title =
    "How Level Works"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SetupInit.request (Route.WelcomeTutorial.getSpaceSlug params)
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
                [ "Everyone" ]
                resp.digestSettings
                resp.nudges
                resp.timeZone
                False
                1
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


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
    | BackUp
    | Advance
    | SkipClicked
    | GroupToggled String
    | SubmitGroups
    | GroupsSubmitted (Result Session.Error ( Session, BulkCreateGroups.Response ))
    | LinkCopied
    | LinkCopyFailed
    | StepUpdated (Result Session.Error ( Session, UpdateTutorialStep.Response ))
    | MarkedComplete (Result Session.Error ( Session, MarkTutorialComplete.Response ))
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
                    Route.pushUrl globals.navKey (inboxRoute model.params)
            in
            ( ( model, Cmd.batch [ completeCmd, redirectCmd ] ), globals )

        GroupToggled name ->
            if List.member name model.selectedGroups then
                ( ( { model | selectedGroups = removeBy identity name model.selectedGroups }, Cmd.none ), globals )

            else
                ( ( { model | selectedGroups = name :: model.selectedGroups }, Cmd.none ), globals )

        SubmitGroups ->
            let
                cmd =
                    globals.session
                        |> BulkCreateGroups.request model.spaceId model.selectedGroups
                        |> Task.attempt GroupsSubmitted
            in
            ( ( { model | isSubmitting = True }, cmd ), globals )

        GroupsSubmitted (Ok ( newSession, BulkCreateGroups.Success )) ->
            let
                newParams =
                    model.params
                        |> Route.WelcomeTutorial.setStep (Route.WelcomeTutorial.getStep model.params + 1)

                cmd =
                    Route.pushUrl globals.navKey (Route.WelcomeTutorial newParams)
            in
            ( ( { model | isSubmitting = False }, cmd ), { globals | session = newSession } )

        GroupsSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        GroupsSubmitted (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals )

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
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        _ ->
            ( model, Cmd.none )


consumeKeyboardEvent : Globals -> KeyboardShortcuts.Event -> Model -> ( ( Model, Cmd Msg ), Globals )
consumeKeyboardEvent globals event model =
    case ( event.key, event.modifiers ) of
        ( "ArrowLeft", [] ) ->
            backUp globals model

        ( "ArrowRight", [] ) ->
            advance globals model

        _ ->
            if
                Route.WelcomeTutorial.getStep model.params
                    == 6
                    && ( event.key, event.modifiers )
                    == keyboardTutorialCommand model.keyboardTutorialStep
            then
                ( ( { model | keyboardTutorialStep = model.keyboardTutorialStep + 1 }, Cmd.none ), globals )

            else
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
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , showKeyboardCommands = globals.showKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div
            [ classList
                [ ( "mx-auto leading-normal p-8", True )
                , ( "max-w-xl", step == 6 )
                , ( "max-w-sm", step /= 6 )
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
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
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
        [ div [ class "p-4 text-lg leading-normal" ]
            [ progressBarView step
            , stepView Device.Mobile step model data
            ]
        ]



-- SHARED


headerView : Int -> Data -> Html Msg
headerView step data =
    if step == 1 then
        h1 [ class "mt-16 mb-6 font-bold tracking-semi-tight text-4xl leading-tighter text-dusty-blue-darkest" ]
            [ div [] [ text "Welcome to Level," ]
            , div [] [ text <| SpaceUser.firstName data.viewer ]
            ]

    else
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
                [ p [ class "mb-6" ] [ text "Hi 👋 I’m Derrick, the creator of Level." ]
                , p [ class "mb-6" ] [ text "Imagine how work would feel if your communication tools weren’t constantly vying for your attention?" ]
                , p [ class "mb-6" ] [ text "Level is designed to help you transition from harried workdays, filled with constant interruptions, to productive workdays, punctuated by moments of thoughtful conversation with your teammates." ]
                , p [ class "mb-6" ] [ text "It won’t always be easy—after all, the dopamine hits supplied by real-time chat are highly addictive—but I promise kicking the habit is a worthwhile endeavor." ]
                , div [ class "mb-4 pb-6" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Let’s get started" ] ]

                -- button [ onClick SkipClicked, class "flex items-center text-base text-dusty-blue font-bold no-underline" ]
                -- [ span [ class "mr-2" ] [ text "Already know Level? Skip to manually set it up" ]
                -- , Icons.arrowRight Icons.On
                -- ]
                ]

        2 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Groups organize your conversations." ]
                , viewIf (SpaceUser.role data.viewer == SpaceUser.Owner) (createGroupsView model)
                , viewIf (SpaceUser.role data.viewer /= SpaceUser.Owner) <|
                    div []
                        [ p [ class "mb-6" ] [ text "After this tutorial, click on “Groups” in the left sidebar to explore them." ]
                        , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                        ]
                , backButton "Previous"
                ]

        3 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "The Inbox is your curated to-do list." ]
                , p [ class "mb-6" ] [ text "It’s impossible to keep up with every conversation in your organization." ]
                , p [ class "mb-6" ] [ text "The Inbox is designed to prevent important discussions from slipping through the cracks and combat information overload." ]
                , p [ class "mb-6" ] [ text "It’s pretty simple: posts will move into your Inbox when you are @-mentioned, or when there’s new activity on a post you've interacted with in the past." ]
                , p [ class "mb-6" ] [ text "Like a to-do list, you should dismiss items from your Inbox when you’re finished with them—they’ll automatically move back in to your Inbox if more activity occurs later." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        4 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "The Feed keeps you in the loop." ]
                , p [ class "mb-6" ] [ text "The Feed gives you a bird’s eye view of all the discussions happening in the Groups you’ve joined." ]
                , p [ class "mb-6" ] [ text "It’s a good idea to periodically skim through it, but don’t feel like you have to keep up with every post there!" ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        5 ->
            let
                nudgesConfig =
                    View.Nudges.Config NudgeToggled model.nudges model.timeZone
            in
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Notifications are batched to minimize distractions." ]
                , p [ class "mb-6" ] [ text "On average, it takes 23 minutes to get back to a task after being interrupted." ]
                , p [ class "mb-6" ] [ text "Since 99% of messages are not so urgent they warrant paying that penalty, Level batches up your notifications and emails them to you when you want them." ]
                , p [ class "mb-6" ] [ text "I’ve chosen some defaults for you, but feel free to toggle times below to fit your schedule. You can always adjust this later in your Settings." ]
                , div [ class "mb-6" ]
                    [ viewIf (device == Device.Desktop) (View.Nudges.desktopView nudgesConfig)
                    , viewIf (device == Device.Mobile) (View.Nudges.mobileView nudgesConfig)
                    ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        6 ->
            div []
                [ h2 [ class "mb-6 max-w-sm text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Command the interface with your keyboard." ]
                , div [ class "xl:flex mb-4 border-b" ]
                    [ div [ class "pb-6 mr-16 max-w-sm" ]
                        [ p [ class "mb-6" ] [ text "Follow the prompts below to learn the most essential keyboard commands." ]
                        , keyboardTutorialStepView model.keyboardTutorialStep
                        ]
                    , div [ class "pb-6 max-w-sm" ]
                        [ keyboardTutorialGraphicView model.keyboardTutorialStep ]
                    ]
                , backButton "Previous"
                ]

        7 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Who’s online? Who cares." ]
                , p [ class "mb-6" ] [ text "Being signed in to a communication tool is not a good indicator of whether someone’s actually available to talk. For that reason, Level does not track who’s currently “online.”" ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        8 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "You’re ready to go!" ]
                , p [ class "mb-6" ] [ text "If you have any questions, please don’t hesitate to reach out to support. You can always revisit this tutorial later by heading to the Help section in the left sidebar." ]
                , div [ class "mb-4 pb-6 border-b" ] [ a [ Route.href <| inboxRoute model.params, class "btn btn-blue no-underline" ] [ text "Take me to Level" ] ]
                , backButton "Previous"
                ]

        _ ->
            text ""


backButton : String -> Html Msg
backButton buttonText =
    button [ class "flex items-center text-base text-dusty-blue font-bold", onClick BackUp ]
        [ span [ class "mr-2" ] [ Icons.arrowLeft Icons.On ]
        , text buttonText
        ]


inboxRoute : Params -> Route
inboxRoute params =
    Route.Inbox (Route.Inbox.init (Route.WelcomeTutorial.getSpaceSlug params))


createGroupsView : Model -> Html Msg
createGroupsView model =
    div []
        [ p [ class "mb-6" ] [ text "I recommend starting out by creating a Group for each team within your organization. Here are a few common ones to choose from. Of course, you can always add more later." ]
        , div [ class "mb-6" ] (List.map (groupCheckbox model.selectedGroups) defaultGroups)
        , div [ class "mb-4 pb-6 border-b" ]
            [ button [ class "btn btn-blue", onClick SubmitGroups, disabled model.isSubmitting ] [ text "Next step" ]
            ]
        ]


groupCheckbox : List String -> String -> Html Msg
groupCheckbox selectedGroups name =
    label [ class "control checkbox mb-1" ]
        [ input
            [ type_ "checkbox"
            , class "checkbox"
            , onClick (GroupToggled name)
            , checked (List.member name selectedGroups)
            ]
            []
        , span [ class "control-indicator" ] []
        , span [ class "select-none" ] [ text name ]
        ]


inviteView : Maybe String -> Html Msg
inviteView maybeUrl =
    case maybeUrl of
        Just url ->
            div []
                [ p [ class "mb-6" ] [ text "Anyone with this link can join the space with member-level permissions. You can always find this link later in the right-hand sidebar of your Inbox." ]
                , div [ class "mb-6 flex items-center input-field bg-grey-lighter border-none" ]
                    [ span [ class "mr-4 flex-shrink font-mono text-base overflow-auto" ] [ text url ]
                    , Clipboard.button "Copy"
                        url
                        [ class "btn btn-blue btn-xs flex items-center"
                        , Clipboard.onCopy LinkCopied
                        , Clipboard.onCopyFailed LinkCopyFailed
                        ]
                    ]
                ]

        Nothing ->
            div []
                [ p [ class "mb-6" ] [ text "Open invitations are disabled." ]
                ]



-- KEYBOARD TUTORIAL


keyboardTutorialCommands : Dict Int ( String, List Modifier )
keyboardTutorialCommands =
    Dict.fromList
        [ ( 1, ( "j", [] ) )
        , ( 2, ( "k", [] ) )
        , ( 3, ( "r", [] ) )
        , ( 4, ( "Enter", [ Meta ] ) )
        , ( 5, ( "Escape", [] ) )
        , ( 6, ( "e", [] ) )
        ]


keyboardTutorialCommand : Int -> ( String, List Modifier )
keyboardTutorialCommand step =
    Dict.get step keyboardTutorialCommands
        |> Maybe.withDefault ( "", [] )


keyboardTutorialStepView : Int -> Html Msg
keyboardTutorialStepView step =
    case step of
        1 ->
            div []
                [ h3 [ class "mb-4 text-2xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Navigate through posts" ]
                , p [ class "mb-6" ] [ text "The grey bar on the left indicates which post is currently selected." ]
                , p [ class "mb-6" ]
                    [ text "Press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-blue text-white font-bold" ] [ text "j" ]
                    , text " to select the next post in the list."
                    ]
                ]

        2 ->
            div []
                [ h3 [ class "mb-4 text-2xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Navigate through posts" ]
                , p [ class "mb-6" ] [ text "The grey bar on the left indicates which post is currently selected." ]
                , p [ class "mb-6" ]
                    [ text "Press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-blue text-white font-bold" ] [ text "k" ]
                    , text " to select the previous post."
                    ]
                ]

        3 ->
            div []
                [ h3 [ class "mb-4 text-2xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Expand the reply composer" ]
                , p [ class "mb-6" ]
                    [ text "Press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-blue text-white font-bold" ] [ text "r" ]
                    , text " to start replying to the selected post."
                    ]
                ]

        4 ->
            div []
                [ h3 [ class "mb-4 text-2xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Submit a reply" ]
                , p [ class "mb-6" ]
                    [ text "Press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-blue text-white font-bold" ] [ text "⌘ + Enter" ]
                    , text " to send the reply."
                    ]
                ]

        5 ->
            div []
                [ h3 [ class "mb-4 text-2xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Close the reply composer" ]
                , p [ class "mb-6" ]
                    [ text "If you have no more replies to send, press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-blue text-white font-bold" ] [ text "esc" ]
                    , text " to close the reply editor."
                    ]
                ]

        6 ->
            div []
                [ h3 [ class "mb-4 text-2xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Dismiss posts from your Inbox" ]
                , p [ class "mb-6" ]
                    [ text "When the "
                    , span [ class "mx-1 inline-block" ] [ Icons.inbox Icons.On ]
                    , text " symbol is highlighted in green, that indicates the post is in your Inbox. It's best to dismiss posts from your Inbox once you are finished following up."
                    ]
                , p [ class "mb-6" ]
                    [ text "Press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-blue text-white font-bold" ] [ text "e" ]
                    , text " to dismiss the selected post."
                    ]
                ]

        7 ->
            div []
                [ h3 [ class "mb-4 text-2xl font-bold text-dusty-blue-darkest tracking-semi-tight leading-tighter" ] [ text "Learn as you go" ]
                , p [ class "mb-6" ]
                    [ text "There are even more keyboard commands to help you smoothly navigate around Level!"
                    ]
                , p [ class "mb-6" ]
                    [ text "Press "
                    , code [ class "mx-1 px-3 py-1 rounded bg-grey font-bold" ] [ text "?" ]
                    , text " any time to see all the shortcuts."
                    ]
                , div [] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                ]

        _ ->
            text ""


keyboardTutorialGraphicView : Int -> Html Msg
keyboardTutorialGraphicView step =
    case step of
        1 ->
            Graphics.keyboardTutorial 1

        2 ->
            Graphics.keyboardTutorial 2

        3 ->
            Graphics.keyboardTutorial 1

        4 ->
            Graphics.keyboardTutorial 3

        5 ->
            Graphics.keyboardTutorial 4

        6 ->
            Graphics.keyboardTutorial 5

        7 ->
            Graphics.keyboardTutorial 6

        _ ->
            text ""



-- HELPERS


nudgeAt : Int -> Model -> Maybe Nudge
nudgeAt minute model =
    model.nudges
        |> List.filter (\nudge -> Nudge.minute nudge == minute)
        |> List.head
