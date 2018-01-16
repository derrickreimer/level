module Page.NewInvitation exposing (ExternalMsg(..), Model, Msg, buildModel, initialCmd, update, view)

import Dom exposing (focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Task
import Data.Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorsFor)
import Mutation.CreateInvitation as CreateInvitation
import Util exposing (onEnter)


-- MODEL


type alias Model =
    { email : String
    , isSubmitting : Bool
    , errors : List ValidationError
    }


{-| Builds the initial model for the page.
-}
buildModel : Model
buildModel =
    Model "" False []


{-| Determines whether the form is able to be submitted.
-}
isSubmittable : Model -> Bool
isSubmittable model =
    not (model.email == "") && model.isSubmitting == False


{-| Returns the initial command to run after the page is loaded.
-}
initialCmd : Cmd Msg
initialCmd =
    focusOnEmailField



-- UPDATE


type Msg
    = EmailChanged String
    | Submit
    | Submitted (Result Http.Error CreateInvitation.Response)
    | Focused


type ExternalMsg
    = InvitationCreated
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg session model =
    case msg of
        EmailChanged val ->
            noCmd { model | email = val }

        Submit ->
            let
                request =
                    CreateInvitation.request session.apiToken <|
                        CreateInvitation.Params model.email
            in
                if isSubmittable model then
                    ( ( { model | isSubmitting = True }
                      , Http.send Submitted request
                      )
                    , NoOp
                    )
                else
                    noCmd model

        Submitted (Ok CreateInvitation.Success) ->
            ( ( { model | errors = [], isSubmitting = False, email = "" }
              , focusOnEmailField
              )
            , InvitationCreated
            )

        Submitted (Ok (CreateInvitation.Invalid errors)) ->
            ( ( { model | errors = errors, isSubmitting = False }, Cmd.none ), NoOp )

        Submitted (Err _) ->
            -- TODO: something unexpected went wrong - figure out best way to handle?
            ( ( { model | isSubmitting = False }, Cmd.none ), NoOp )

        Focused ->
            noCmd model


noCmd : Model -> ( ( Model, Cmd Msg ), ExternalMsg )
noCmd model =
    ( ( model, Cmd.none ), NoOp )


focusOnEmailField : Cmd Msg
focusOnEmailField =
    Task.attempt (always Focused) <| focus "email-field"



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "main", class "main main--new-invitation" ]
        [ div [ class "cform" ]
            [ div [ class "cform__header cform__header" ]
                [ h2 [ class "cform__heading" ] [ text "Send an invitation" ]
                , p [ class "cform__description" ]
                    [ text "Invite someone to join this Level space." ]
                ]
            , div [ class "cform__form" ]
                [ inputField "email" "email" "Email Address" model.email EmailChanged model
                , div [ class "form-controls" ]
                    [ input
                        [ type_ "submit"
                        , value "Send now"
                        , class "button button--primary button--large"
                        , disabled (not <| isSubmittable model)
                        , onClick Submit
                        ]
                        []
                    ]
                ]
            ]
        ]


inputField : String -> String -> String -> String -> (String -> Msg) -> Model -> Html Msg
inputField fieldType fieldName labelText fieldValue inputMsg model =
    let
        errors =
            errorsFor fieldName model.errors
    in
        div
            [ classList
                [ ( "form-field", True )
                , ( "form-field--error", not (List.isEmpty errors) )
                ]
            ]
            [ label [ class "form-label" ] [ text labelText ]
            , input
                [ type_ fieldType
                , id (fieldName ++ "-field")
                , class "text-field text-field--full text-field--large"
                , name fieldName
                , value fieldValue
                , onInput inputMsg
                , onEnter Submit
                , disabled model.isSubmitting
                ]
                []
            , formErrors errors
            ]


formErrors : List ValidationError -> Html Msg
formErrors errors =
    case errors of
        error :: _ ->
            div [ class "form-errors" ] [ text error.message ]

        [] ->
            text ""
