module Page.NewRoom exposing (ExternalMsg(..), Model, Msg, initialModel, initialCmd, update, view)

import Dom exposing (focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Task
import Data.Room exposing (RoomSubscription)
import Data.Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorsFor)
import Mutation.CreateRoom as CreateRoom
import Route
import Util exposing (onEnter)


-- MODEL


type alias Model =
    { name : String
    , description : String
    , isPrivate : Bool
    , isSubmitting : Bool
    , errors : List ValidationError
    }


{-| Builds the initial model for the page.
-}
initialModel : Model
initialModel =
    Model "" "" False False []


{-| Returns the initial command to run after the page is loaded.
-}
initialCmd : Cmd Msg
initialCmd =
    Task.attempt (always Focused) <| focus "name-field"


{-| Determines whether the form is able to be submitted.
-}
isSubmittable : Model -> Bool
isSubmittable model =
    not (model.name == "") && model.isSubmitting == False



-- UPDATE


type Msg
    = NameChanged String
    | DescriptionChanged String
    | PrivacyToggled
    | Submit
    | Submitted (Result Http.Error CreateRoom.Response)
    | Focused


type ExternalMsg
    = NoOp
    | RoomCreated RoomSubscription


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg session model =
    case msg of
        NameChanged val ->
            ( ( { model | name = val }, Cmd.none ), NoOp )

        DescriptionChanged val ->
            ( ( { model | description = val }, Cmd.none ), NoOp )

        PrivacyToggled ->
            ( ( { model | isPrivate = not model.isPrivate }, Cmd.none ), NoOp )

        Submit ->
            let
                subscriberPolicy =
                    if model.isPrivate == True then
                        "INVITE_ONLY"
                    else
                        "PUBLIC"

                request =
                    CreateRoom.request session.apiToken <|
                        CreateRoom.Params model.name model.description subscriberPolicy
            in
                if isSubmittable model then
                    ( ( { model | isSubmitting = True }
                      , Http.send Submitted request
                      )
                    , NoOp
                    )
                else
                    ( ( model, Cmd.none ), NoOp )

        Submitted (Ok (CreateRoom.Success roomSubscription)) ->
            ( ( model, Route.modifyUrl <| Route.Room roomSubscription.room.id )
            , RoomCreated roomSubscription
            )

        Submitted (Ok (CreateRoom.Invalid errors)) ->
            ( ( { model | errors = errors, isSubmitting = False }, Cmd.none ), NoOp )

        Submitted (Err _) ->
            -- TODO: something unexpected went wrong - figure out best way to handle?
            ( ( model, Cmd.none ), NoOp )

        Focused ->
            ( ( model, Cmd.none ), NoOp )



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "main", class "main main--new-room" ]
        [ div [ class "cform" ]
            [ div [ class "cform__header cform__header" ]
                [ h2 [ class "cform__heading" ] [ text "Create a room" ]
                , p [ class "cform__description" ]
                    [ text "Rooms are where spontaneous discussions take place. If the topic is important, a conversation is better venue." ]
                ]
            , div [ class "cform__form" ]
                [ inputField "name" "Room Name" NameChanged model
                , inputField "description" "Description (optional)" DescriptionChanged model
                , div [ class "form-field" ]
                    [ div [ class "checkbox-toggle" ]
                        [ input
                            [ type_ "checkbox"
                            , id "private"
                            , checked model.isPrivate
                            , onClick PrivacyToggled
                            ]
                            []
                        , label [ class "checkbox-toggle__label", for "private" ]
                            [ span [ class "checkbox-toggle__switch" ] []
                            , text "Make this room private"
                            ]
                        ]
                    ]
                , div [ class "form-controls" ]
                    [ input
                        [ type_ "submit"
                        , value "Create room"
                        , class "button button--primary button--large"
                        , disabled (not <| isSubmittable model)
                        , onClick Submit
                        ]
                        []
                    ]
                ]
            ]
        ]


inputField : String -> String -> (String -> Msg) -> Model -> Html Msg
inputField fieldName labelText inputMsg model =
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
                [ type_ "text"
                , id (fieldName ++ "-field")
                , class "text-field text-field--full text-field--large"
                , name fieldName
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
