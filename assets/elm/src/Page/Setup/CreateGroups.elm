module Page.Setup.CreateGroups exposing (ExternalMsg(..), Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
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
buildModel ( session, { viewer, space, bookmarks } ) =
    let
        model =
            Model
                viewer
                space
                bookmarks
                False
                [ "All Teams" ]
    in
    Task.succeed ( session, model )


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
                        |> BulkCreateGroups.request (Space.id model.space) groups
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True }, cmd ), globals, NoOp )

        Submitted (Ok ( newSession, BulkCreateGroups.Success )) ->
            let
                cmd =
                    newSession
                        |> CompleteSetupStep.request (Space.id model.space) Space.CreateGroups False
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
            ( { model | bookmarks = insertUniqueBy Group.id group model.bookmarks }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarks = removeBy Group.id group model.bookmarks }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute ({ viewer, space, bookmarks } as model) =
    let
        viewerData =
            Repo.getSpaceUser repo model.viewer
    in
    spaceLayout
        viewer
        space
        bookmarks
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
