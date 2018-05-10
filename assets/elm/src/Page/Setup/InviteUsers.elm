module Page.Setup.InviteUsers exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Task
import Session exposing (Session)
import Data.Setup as Setup
import Mutation.CompleteSetupStep as CompleteSetupStep
import Route


-- MODEL


type alias Model =
    { spaceId : String
    , isSubmitting : Bool
    }


buildModel : String -> Model
buildModel spaceId =
    Model spaceId False



-- UPDATE


type Msg
    = Submit
    | Advanced (Result Session.Error ( Session, CompleteSetupStep.Response ))


type ExternalMsg
    = SessionRefreshed Session
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg session model =
    case msg of
        Submit ->
            let
                cmd =
                    CompleteSetupStep.Params model.spaceId Setup.InviteUsers False
                        |> CompleteSetupStep.request
                        |> Session.request session
                        |> Task.attempt Advanced
            in
                ( ( { model | isSubmitting = True }, cmd ), NoOp )

        Advanced (Ok ( session, CompleteSetupStep.Success nextState )) ->
            ( ( model, Cmd.none ), SessionRefreshed session )

        Advanced (Err Session.Expired) ->
            redirectToLogin model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), NoOp )


redirectToLogin : Model -> ( ( Model, Cmd Msg ), ExternalMsg )
redirectToLogin model =
    ( ( model, Route.toLogin ), NoOp )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto py-24 max-w-430px leading-normal text-dusty-blue-darker" ]
            [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text "Invite your colleagues" ]
            , p [ class "mb-6" ] [ text "The best way to try out Level is with other people! Anyone with this link can join the space (click to copy it):" ]
            , p [ class "mb-6" ] [ text "TODO: Add the shared invite link here" ]
            , button [ class "btn btn-blue", onClick Submit, disabled model.isSubmitting ] [ text "Next step" ]
            ]
        ]
