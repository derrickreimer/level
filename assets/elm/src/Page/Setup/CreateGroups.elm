module Page.Setup.CreateGroups exposing (ExternalMsg(..), Model, Msg(..), init, setup, teardown, title, update, view)

import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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
    { viewer : SpaceUser
    , space : Space
    , bookmarkedGroups : List Group
    , isSubmitting : Bool
    , selectedGroups : List String
    }


defaultGroups : List String
defaultGroups =
    [ "All Teams", "Engineering", "Marketing", "Support", "Random" ]



-- PAGE PROPERTIES


title : String
title =
    "Setup your groups"



-- LIFECYCLE


init : String -> Session -> Task Session.Error ( Session, Model )
init spaceSlug session =
    session
        |> SetupInit.request spaceSlug
        |> Task.andThen buildModel


buildModel : ( Session, SetupInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { viewer, space, bookmarkedGroups } ) =
    let
        model =
            Model
                viewer
                space
                bookmarkedGroups
                False
                [ "All Teams" ]
    in
    Task.succeed ( session, model )


setup : Cmd Msg
setup =
    Cmd.none


teardown : Cmd Msg
teardown =
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


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
update msg session model =
    let
        groups =
            model.selectedGroups
    in
    case msg of
        GroupToggled name ->
            if List.member name groups then
                ( ( { model | selectedGroups = remove name groups }, Cmd.none ), session, NoOp )

            else
                ( ( { model | selectedGroups = name :: groups }, Cmd.none ), session, NoOp )

        Submit ->
            let
                cmd =
                    session
                        |> BulkCreateGroups.request (Space.getId model.space) groups
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True }, cmd ), session, NoOp )

        Submitted (Ok ( newSession, BulkCreateGroups.Success )) ->
            let
                cmd =
                    newSession
                        |> CompleteSetupStep.request (Space.getId model.space) Space.CreateGroups False
                        |> Task.attempt Advanced
            in
            ( ( model, cmd ), newSession, NoOp )

        Submitted (Err Session.Expired) ->
            redirectToLogin session model

        Submitted (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), session, NoOp )

        Advanced (Ok ( newSession, CompleteSetupStep.Success nextState )) ->
            -- TODO: Re-instate navigation to next state
            ( ( model, Cmd.none ), newSession, SetupStateChanged nextState )

        Advanced (Err Session.Expired) ->
            redirectToLogin session model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), session, NoOp )


remove : String -> List String -> List String
remove name list =
    List.filter (\item -> not (item == name)) list


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session, NoOp )



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute ({ viewer, space, bookmarkedGroups } as model) =
    let
        viewerData =
            Repo.getSpaceUser repo model.viewer
    in
    spaceLayout repo
        viewer
        space
        bookmarkedGroups
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto py-24 max-w-400px leading-normal" ]
                [ h2 [ class "mb-6 font-extrabold text-3xl" ] [ text ("Welcome to Level, " ++ viewerData.firstName ++ "!") ]
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
