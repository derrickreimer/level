module Page.Setup.CreateGroups exposing (ExternalMsg(..), Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BulkCreateGroups as BulkCreateGroups
import Mutation.CompleteSetupStep as CompleteSetupStep
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { spaceSlug : String
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , isSubmitting : Bool
    , selectedGroups : List String
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
    [ "All Teams", "Engineering", "Marketing", "Support", "Random" ]



-- PAGE PROPERTIES


title : String
title =
    "Setup your groups"



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
                resp.bookmarkIds
                False
                [ "All Teams" ]

        repo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = repo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = GroupToggled String
    | Submit
    | Submitted (Result Session.Error ( Session, BulkCreateGroups.Response ))
    | Advanced (Result Session.Error ( Session, CompleteSetupStep.Response ))


type ExternalMsg
    = SetupStateChanged Space.SetupState
    | NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals, ExternalMsg )
update msg globals model =
    let
        groups =
            model.selectedGroups
    in
    case msg of
        GroupToggled name ->
            if List.member name groups then
                ( ( { model | selectedGroups = remove name groups }, Cmd.none ), globals, NoOp )

            else
                ( ( { model | selectedGroups = name :: groups }, Cmd.none ), globals, NoOp )

        Submit ->
            let
                cmd =
                    globals.session
                        |> BulkCreateGroups.request model.spaceId groups
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True }, cmd ), globals, NoOp )

        Submitted (Ok ( newSession, BulkCreateGroups.Success )) ->
            let
                cmd =
                    newSession
                        |> CompleteSetupStep.request model.spaceId Space.CreateGroups False
                        |> Task.attempt Advanced
            in
            ( ( model, cmd ), { globals | session = newSession }, NoOp )

        Submitted (Err Session.Expired) ->
            redirectToLogin globals model

        Submitted (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals, NoOp )

        Advanced (Ok ( newSession, CompleteSetupStep.Success nextState )) ->
            -- TODO: Re-instate navigation to next state
            ( ( model, Cmd.none ), { globals | session = newSession }, SetupStateChanged nextState )

        Advanced (Err Session.Expired) ->
            redirectToLogin globals model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals, NoOp )


remove : String -> List String -> List String
remove name list =
    List.filter (\item -> not (item == name)) list


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals, ExternalMsg )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals, NoOp )



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
            resolvedView maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Maybe Route -> Model -> Data -> Html Msg
resolvedView maybeCurrentRoute model data =
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto py-24 max-w-400px leading-normal" ]
                [ h2 [ class "mb-6 font-extrabold text-3xl" ] [ text ("Welcome to Level, " ++ SpaceUser.firstName data.viewer ++ "!") ]
                , p [ class "mb-6" ] [ text "To kick things off, let’s create some groups. We've assembled some common ones to choose from, but you can always create more later." ]
                , p [ class "mb-6" ] [ text "Select the groups you'd like to create:" ]
                , div [ class "mb-6" ] (List.map (groupCheckbox model.selectedGroups) defaultGroups)
                , button [ class "btn btn-blue", onClick Submit, disabled model.isSubmitting ] [ text "Create these groups" ]
                ]
            ]
        ]


groupCheckbox : List String -> String -> Html Msg
groupCheckbox selectedGroups name =
    label [ class "control checkbox mb-2" ]
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
