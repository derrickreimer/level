module Page.Setup.InviteUsers exposing (ExternalMsg(..), Model, Msg(..), buildModel, init, setup, teardown, title, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Mutation.CompleteSetupStep as CompleteSetupStep
import Route exposing (Route)
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)



-- MODEL


type alias Model =
    { spaceId : String
    , isSubmitting : Bool
    , openInvitationUrl : Maybe String
    }



-- PAGE PROPERTIES


title : String
title =
    "Invite your colleagues"



-- LIFECYCLE


init : Space -> Task Never Model
init space =
    Task.succeed (buildModel space)


buildModel : Space -> Model
buildModel space =
    let
        spaceData =
            Space.getCachedData space
    in
    Model (Space.getId space) False spaceData.openInvitationUrl


setup : Cmd Msg
setup =
    Cmd.none


teardown : Cmd Msg
teardown =
    Cmd.none



-- UPDATE


type Msg
    = Submit
    | Advanced (Result Session.Error ( Session, CompleteSetupStep.Response ))


type ExternalMsg
    = SetupStateChanged Space.SetupState
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
update msg session model =
    case msg of
        Submit ->
            let
                cmd =
                    CompleteSetupStep.request model.spaceId Space.InviteUsers False session
                        |> Task.attempt Advanced
            in
            ( ( { model | isSubmitting = True }, cmd ), session, NoOp )

        Advanced (Ok ( newSession, CompleteSetupStep.Success nextState )) ->
            -- TODO: Re-instate navigation to next state
            ( ( model, Cmd.none ), newSession, SetupStateChanged nextState )

        Advanced (Err Session.Expired) ->
            redirectToLogin session model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), session, NoOp )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session, NoOp )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto py-24 max-w-400px leading-normal" ]
            [ h2 [ class "mb-6 font-extrabold text-3xl" ] [ text "Invite your colleagues" ]
            , body model.openInvitationUrl
            , button [ class "btn btn-blue", onClick Submit, disabled model.isSubmitting ] [ text "Next step" ]
            ]
        ]


body : Maybe String -> Html Msg
body maybeUrl =
    case maybeUrl of
        Just url ->
            div []
                [ p [ class "mb-6" ] [ text "The best way to try out Level is with other people! Anyone with this link can join the space:" ]
                , input [ class "mb-6 input-field font-mono text-sm", value url ] []
                ]

        Nothing ->
            p [ class "mb-6" ] [ text "Open invitations are disabled." ]
