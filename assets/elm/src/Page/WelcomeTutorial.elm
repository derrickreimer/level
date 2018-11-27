module Page.WelcomeTutorial exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Browser.Navigation as Nav
import Clipboard
import Event exposing (Event)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BulkCreateGroups as BulkCreateGroups
import Mutation.CreateGroup as CreateGroup
import Mutation.MarkTutorialComplete as MarkTutorialComplete
import Mutation.UpdateTutorialStep as UpdateTutorialStep
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.Inbox
import Route.WelcomeTutorial exposing (Params)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, viewIf)
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , selectedGroups : List String
    , isSubmitting : Bool
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
    9



-- PAGE PROPERTIES


title : String
title =
    "Welcome to Level"



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
    | GroupToggled String
    | SubmitGroups
    | GroupsSubmitted (Result Session.Error ( Session, BulkCreateGroups.Response ))
    | LinkCopied
    | LinkCopyFailed
    | StepUpdated (Result Session.Error ( Session, UpdateTutorialStep.Response ))
    | MarkedComplete (Result Session.Error ( Session, MarkTutorialComplete.Response ))


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        BackUp ->
            let
                newParams =
                    model.params
                        |> Route.WelcomeTutorial.setStep (Route.WelcomeTutorial.getStep model.params - 1)

                cmd =
                    Route.pushUrl globals.navKey (Route.WelcomeTutorial newParams)
            in
            ( ( model, cmd ), globals )

        Advance ->
            let
                newParams =
                    model.params
                        |> Route.WelcomeTutorial.setStep (Route.WelcomeTutorial.getStep model.params + 1)

                cmd =
                    Route.pushUrl globals.navKey (Route.WelcomeTutorial newParams)
            in
            ( ( model, cmd ), globals )

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


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    case resolveData repo model of
        Just data ->
            resolvedView repo maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> Maybe Route -> Model -> Data -> Html Msg
resolvedView repo maybeCurrentRoute model data =
    let
        step =
            Route.WelcomeTutorial.getStep model.params
    in
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "pb-6 text-lg text-dusty-blue-darker" ]
                [ headerView step data
                , stepView step model data
                ]
            ]
        ]


headerView : Int -> Data -> Html Msg
headerView step data =
    if step == 1 then
        h1 [ class "mt-16 mb-6 font-extrabold tracking-semi-tight text-4xl leading-tight text-dusty-blue-darkest" ]
            [ text <| "Welcome to Level, " ++ SpaceUser.firstName data.viewer ]

    else
        div []
            [ h1 [ class "mb-3 font-extrabold tracking-semi-tight text-xl leading-tight text-dusty-blue-darkest" ] [ text "Welcome to Level" ]
            , progressBarView step
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
    div [ class "mb-8 flex items-center" ]
        [ div [ class "flex-no-shrink mr-2 w-32 rounded-full bg-grey" ]
            [ div
                [ class "h-1 rounded-full bg-turquoise"
                , style "width" (percentage ++ "%")
                , style "transition" "width 0.5s ease"
                ]
                []
            ]
        ]


stepView : Int -> Model -> Data -> Html Msg
stepView step model data =
    case step of
        1 ->
            div []
                [ p [ class "mb-6" ] [ text "Hi 👋 I’m Derrick, the creator of Level." ]
                , p [ class "mb-6" ] [ text "Let’s face it—we’ve all been conditioned by real-time chat to expect instant responses from our teammates." ]
                , p [ class "mb-6" ] [ text "As a result, our ability to achieve deep focus is suffering. It’s simply unsustainable." ]
                , p [ class "mb-6" ] [ text "I’m so glad you are here pursuing a better way. It’s time to break some bad habits and start embracing asynchronous communication." ]
                , p [ class "mb-6" ] [ text "To get started, join me on quick walk through the fundamental ideas behind Level." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Let’s get started" ] ]
                , a [ Route.href <| inboxRoute model.params, class "flex items-center text-base text-dusty-blue font-bold no-underline" ]
                    [ span [ class "mr-2" ] [ text "Already know Level? Skip the tutorial" ]
                    , Icons.arrowRight Icons.On
                    ]
                ]

        2 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "Groups organize converations." ]
                , p [ class "mb-6" ] [ text "Similar to channels in chat, a group in Level is a place where you can post messages around a particular topic." ]
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
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "Conversations are always threaded." ]
                , p [ class "mb-6" ] [ text "You can either create a post in a group to kick off a new conversation, or reply to an existing post to carry on the discussion." ]
                , p [ class "mb-6" ] [ text "Once the conversation is done, it is best to mark it as resolved to let the rest of the team know." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        4 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "The Inbox is your curated to-do list." ]
                , p [ class "mb-6" ] [ text "It’s neither possible, nor desirable, for any single person to keep up with every conversation. Such an endeavor is stressful and futile." ]
                , p [ class "mb-6" ] [ text "Posts will land in your Inbox when someone loops you in with an @-mention or when you’ve already participated in the conversation and there’s new activity." ]
                , p [ class "mb-6" ] [ text "You can safely dismiss posts from your Inbox when you’re done with them—they’ll move back to your Inbox if more activity occurs later." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        5 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "The Activity feed helps you stay in the loop." ]
                , p [ class "mb-6" ] [ text "Your feed is personalized to only include messages posted in groups that you have joined." ]
                , p [ class "mb-6" ] [ text "Since posts only land in your Inbox if you have been looped in, it’s a good idea to periodically skim through your Activity feed." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        6 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "Level will not interrupt you." ]
                , p [ class "mb-6" ] [ text "On average, it takes 22 minutes to get back into flow after a single interruption. I’m willing to bet that 99% of conversations are not so urgent they warrant paying that penalty." ]
                , p [ class "mb-6" ] [ text "Level will not send push notifications unless you have a true emergency and flag your message accordingly." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        7 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "Level does not track who’s online." ]
                , p [ class "mb-6" ] [ text "Being signed in to a communication tool is not a good indicator of whether someone’s actually available to communicate." ]
                , p [ class "mb-6" ] [ text "And, it’s most definitely not a good proxy for determining whether someone is slacking off." ]
                , p [ class "mb-6" ] [ text "There’s just one exception: if two or more people are looking at the same post, Level will let them know who else is there (in case they want to chat)." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        8 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "You control how often Level nudges you." ]
                , p [ class "mb-6" ] [ text "Level aims to be as unobtrusive as possible. At a minimum, you’ll receive a Daily Digest email summarizing what’s on your plate in your Level Inbox." ]
                , p [ class "mb-6" ] [ text "You can also configure Level to send you periodic emails throughout the day to keep you in the know about new activity." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next step" ] ]
                , backButton "Previous"
                ]

        9 ->
            div []
                [ h2 [ class "mb-6 text-4xl font-extrabold text-dusty-blue-darkest tracking-semi-tight leading-tight" ] [ text "You’re ready to go!" ]
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
        [ p [ class "mb-6" ] [ text "To kick things off, let’s create some groups. Here are some common ones to choose from, but you can always create more later." ]
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
