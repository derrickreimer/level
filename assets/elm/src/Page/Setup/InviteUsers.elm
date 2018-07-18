module Page.Setup.InviteUsers
    exposing
        ( Model
        , Msg(..)
        , ExternalMsg(..)
        , buildModel
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Task
import Session exposing (Session)
import Data.Setup as Setup
import Mutation.CompleteSetupStep as CompleteSetupStep
import Route exposing (Route)


-- MODEL


type alias Model =
    { spaceId : String
    , isSubmitting : Bool
    , openInvitationUrl : Maybe String
    }


buildModel : String -> Maybe String -> Model
buildModel spaceId openInvitationUrl =
    Model spaceId False openInvitationUrl



-- UPDATE


type Msg
    = Submit
    | Advanced (Result Session.Error ( Session, CompleteSetupStep.Response ))


type ExternalMsg
    = SetupStateChanged Setup.State
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
update msg session model =
    case msg of
        Submit ->
            let
                cmd =
                    CompleteSetupStep.request model.spaceId Setup.InviteUsers False session
                        |> Task.attempt Advanced
            in
                ( ( { model | isSubmitting = True }, cmd ), session, NoOp )

        Advanced (Ok ( session, CompleteSetupStep.Success nextState )) ->
            ( ( model, Route.modifyUrl <| routeFor nextState ), session, SetupStateChanged nextState )

        Advanced (Err Session.Expired) ->
            redirectToLogin session model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), session, NoOp )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session, ExternalMsg )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session, NoOp )


routeFor : Setup.State -> Route
routeFor setupState =
    case setupState of
        Setup.CreateGroups ->
            Route.SetupCreateGroups

        Setup.InviteUsers ->
            Route.SetupInviteUsers

        Setup.Complete ->
            Route.Inbox



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto py-24 max-w-400px leading-normal text-dusty-blue-darker" ]
            [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text "Invite your colleagues" ]
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
