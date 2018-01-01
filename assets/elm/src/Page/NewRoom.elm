module Page.NewRoom exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Data.Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorsFor)
import Mutation.CreateRoom as CreateRoom


-- MODEL


type alias Model =
    { name : String
    , description : String
    , isSubmitting : Bool
    , errors : List ValidationError
    }


{-| Builds the initial model for the page.
-}
initialModel : Model
initialModel =
    Model "" "" False []


{-| Determines whether the form is able to be submitted.
-}
isSubmittable : Model -> Bool
isSubmittable model =
    not (model.name == "") && model.isSubmitting == False



-- UPDATE


type Msg
    = NameChanged String
    | DescriptionChanged String
    | Submit
    | Submitted (Result Http.Error CreateRoom.Response)


update : Msg -> Session -> Model -> ( Model, Cmd Msg )
update msg session model =
    case msg of
        NameChanged val ->
            ( { model | name = val }, Cmd.none )

        DescriptionChanged val ->
            ( { model | description = val }, Cmd.none )

        Submit ->
            let
                request =
                    CreateRoom.request session.apiToken <|
                        CreateRoom.Params model.name model.description
            in
                if isSubmittable model then
                    ( { model | isSubmitting = True }
                    , Http.send Submitted request
                    )
                else
                    ( model, Cmd.none )

        Submitted (Ok (CreateRoom.Success room)) ->
            -- TODO: add to the sidebar, redirect to the room
            ( model, Cmd.none )

        Submitted (Ok (CreateRoom.Invalid errors)) ->
            -- TODO: render validation errors
            ( { model | errors = errors }, Cmd.none )

        Submitted (Err _) ->
            -- TODO: render errors
            ( model, Cmd.none )



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
                [ inputField "name" "Room Name" NameChanged (errorsFor "name" model.errors)
                , inputField "description" "Description (optional)" DescriptionChanged (errorsFor "description" model.errors)
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


inputField : String -> String -> (String -> Msg) -> List ValidationError -> Html Msg
inputField fieldName labelText inputMsg errors =
    div
        [ classList
            [ ( "form-field", True )
            , ( "form-field--error", not (List.isEmpty errors) )
            ]
        ]
        [ label [ class "form-label" ] [ text labelText ]
        , input
            [ type_ "text"
            , class "text-field text-field--full text-field--large"
            , name fieldName
            , onInput inputMsg
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
