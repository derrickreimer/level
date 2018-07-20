module Page.UserSettings
    exposing
        ( Model
        , Msg(..)
        , init
        , setup
        , teardown
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Task exposing (Task)
import Data.ValidationError exposing (ValidationError, errorsFor, errorsNotFor, isInvalid, errorView)
import Query.UserSettingsInit as UserSettingsInit
import Repo exposing (Repo)
import Session exposing (Session)


-- MODEL


type alias Model =
    { firstName : String
    , lastName : String
    , email : String
    , errors : List ValidationError
    }



-- LIFECYCLE


init : Session -> Task Session.Error ( Session, Model )
init session =
    UserSettingsInit.request session
        |> Task.andThen buildModel


buildModel : ( Session, UserSettingsInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { user } ) =
    let
        model =
            Model user.firstName user.lastName user.email []
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
    = EmailChanged String
    | FirstNameChanged String
    | LastNameChanged String
    | Submit


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        EmailChanged val ->
            noCmd session { model | email = val }

        FirstNameChanged val ->
            noCmd session { model | firstName = val }

        LastNameChanged val ->
            noCmd session { model | lastName = val }

        Submit ->
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )



-- VIEW


view : Repo -> Model -> Html Msg
view repo ({ errors } as model) =
    div [ class "ml-56 mr-24" ]
        [ div [ class "mx-auto max-w-90 leading-normal py-12" ]
            [ h1 [ class "pb-8 font-extrabold text-4xl" ] [ text "User Settings" ]
            , div [ class "pb-6" ]
                [ label [ for "email", class "input-label" ] [ text "Email address" ]
                , input
                    [ id "email"
                    , type_ "email"
                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "email" errors ) ]
                    , name "email"
                    , placeholder "jane@acmeco.com"
                    , value model.email
                    , onInput EmailChanged
                    ]
                    []
                , errorView "email" errors
                ]
            , div [ class "pb-6" ]
                [ label [ for "firstName", class "input-label" ] [ text "First Name" ]
                , input
                    [ id "firstName"
                    , type_ "text"
                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "firstName" errors ) ]
                    , name "firstName"
                    , placeholder "Jane"
                    , value model.firstName
                    , onInput FirstNameChanged
                    ]
                    []
                , errorView "firstName" errors
                ]
            , div [ class "pb-6" ]
                [ label [ for "lastName", class "input-label" ] [ text "Last Name" ]
                , input
                    [ id "lastName"
                    , type_ "text"
                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "lastName" errors ) ]
                    , name "lastName"
                    , placeholder "Doe"
                    , value model.lastName
                    , onInput LastNameChanged
                    ]
                    []
                , errorView "lastName" errors
                ]
            , button
                [ type_ "submit"
                , class "btn btn-blue"
                , onClick Submit
                ]
                [ text "Save Settings" ]
            ]
        ]
