module Page.Tutorial exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Browser.Navigation as Nav
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CreateGroup as CreateGroup
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.Tutorial exposing (Params)
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
    "How Level Works"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SetupInit.request (Route.Tutorial.getSpaceSlug params)
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

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp
    | BackUp
    | Advance


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        BackUp ->
            let
                newParams =
                    model.params
                        |> Route.Tutorial.setStep (Route.Tutorial.getStep model.params - 1)

                cmd =
                    Route.pushUrl globals.navKey (Route.Tutorial newParams)
            in
            ( ( model, cmd ), globals )

        Advance ->
            let
                newParams =
                    model.params
                        |> Route.Tutorial.setStep (Route.Tutorial.getStep model.params + 1)

                cmd =
                    Route.pushUrl globals.navKey (Route.Tutorial newParams)
            in
            ( ( model, cmd ), globals )


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
            Route.Tutorial.getStep model.params
    in
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "pb-6 text-lg" ]
                [ h1 [ class "font-extrabold tracking-semi-tight text-5xl" ] [ text "How Level Works" ]
                , progressBarView step
                , stepView step
                ]
            ]
        ]


progressBarView : Int -> Html Msg
progressBarView step =
    let
        percentage =
            (toFloat step / 8)
                * 100
                |> round
                |> String.fromInt
    in
    div [ class "mb-8 flex items-center" ]
        [ div [ class "flex-no-shrink mr-2 w-48 rounded-full bg-grey-light" ]
            [ div
                [ class "h-2 rounded-full bg-turquoise"
                , style "width" (percentage ++ "%")
                , style "transition" "width 0.5s ease"
                ]
                []
            ]
        , div [ class "text-sm text-dusty-blue" ]
            [ text <| percentage ++ "% complete" ]
        ]


stepView : Int -> Html Msg
stepView step =
    case step of
        1 ->
            div []
                [ p [ class "mb-6" ] [ text "Let’s face it, most product tutorials are pretty boring and uninspired, right? I promise I’ll make this one worth your while." ]
                , p [ class "mb-6" ] [ text "Level works a little differently than most team communication tools on the market today." ]
                , p [ class "mb-6" ] [ text "But, fear not! Level’s actually a really simple tool with a few basic goals: facilitate and organize meaningful conversations with your teammates and stay of your way when you are getting stuff done." ]
                , p [ class "mb-6" ] [ text "Intrigued?" ]
                , button [ class "btn btn-blue", onClick Advance ] [ text "Let’s dive in" ]
                ]

        2 ->
            div []
                [ h2 [ class "mb-6 text-3xl font-extrabold text-dusty-blue-darker tracking-semi-tight leading-tight" ] [ text "There are almost no push notifications." ]
                , p [ class "mb-6" ] [ text "On average, it takes 22 minutes to get back into flow after a single interruption. I’m willing to bet that 99% of conversations are not so urgent they warrant paying that penalty." ]
                , p [ class "mb-6" ] [ text "If you tell Level a message is a true emergency, it will work hard to get the right person’s attention." ]
                , p [ class "mb-6" ] [ text "If two or more people happen to be conversing in real-time, Level will send notifications to keep the conversation flowing smoothly." ]
                , p [ class "mb-6" ] [ text "Otherwise, Level won’t interrupt you." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next" ] ]
                , backButton "Back to Introduction"
                ]

        3 ->
            div []
                [ h2 [ class "mb-6 text-3xl font-extrabold text-dusty-blue-darker tracking-semi-tight leading-tight" ] [ text "Every conversations is threaded." ]
                , p [ class "mb-6" ] [ text "A chat channel is effectively one never-ending conversation." ]
                , p [ class "mb-6" ] [ text "This does not model how real-life, productive discourse takes place. Plus, it’s an organizational nightmare." ]
                , p [ class "mb-6" ] [ text "In Level, you can either post in a group to kick off a new conversation, or reply to an existing post to carry on the discussion." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next" ] ]
                , backButton "Back to \"No push notifications\""
                ]

        4 ->
            div []
                [ h2 [ class "mb-6 text-3xl font-extrabold text-dusty-blue-darker tracking-semi-tight leading-tight" ] [ text "There is no continuous presence tracking." ]
                , p [ class "mb-6" ] [ text "Being signed in to a communication tool is not a good indicator of whether someone's actually available to communicate." ]
                , p [ class "mb-6" ] [ text "It's most definitely not a good proxy for whether someone is \"slacking off.\"" ]
                , p [ class "mb-6" ] [ text "A friend of mine once told me that in his department, everyone would race to see who was the first get \"online\" in the morning—to appear hardworking to their boss. That's bullshit." ]
                , p [ class "mb-6" ] [ text "Level encourages you to step away from it completely when it’s time to get down to work." ]
                , div [ class "mb-4 pb-6 border-b" ] [ button [ class "btn btn-blue", onClick Advance ] [ text "Next" ] ]
                , backButton "Back to \"Every conversation is threaded\""
                ]

        _ ->
            text ""


backButton : String -> Html Msg
backButton buttonText =
    button [ class "flex items-center text-base text-dusty-blue font-bold", onClick BackUp ]
        [ span [ class "mr-2" ] [ Icons.arrowLeft Icons.On ]
        , text buttonText
        ]
