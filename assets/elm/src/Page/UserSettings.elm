module Page.UserSettings
    exposing
        ( Model
        , Msg(..)
        , init
        , setup
        , teardown
        , update
        , subscriptions
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Task exposing (Task)
import Data.ValidationError exposing (ValidationError, errorsFor, errorsNotFor, isInvalid, errorView)
import File exposing (File)
import Mutation.UpdateUser as UpdateUser
import Query.UserSettingsInit as UserSettingsInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)


-- MODEL


type alias Model =
    { firstName : String
    , lastName : String
    , email : String
    , errors : List ValidationError
    , isSubmitting : Bool
    , newAvatar : Maybe File
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
            Model user.firstName user.lastName user.email [] False Nothing
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
    | Submitted (Result Session.Error ( Session, UpdateUser.Response ))
    | AvatarSelected
    | FileReceived File.Data


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
            let
                cmd =
                    session
                        |> UpdateUser.request model.firstName model.lastName model.email
                        |> Task.attempt Submitted
            in
                ( ( { model | isSubmitting = True }, cmd ), session )

        Submitted (Ok ( session, UpdateUser.Success user )) ->
            noCmd session
                { model
                    | firstName = user.firstName
                    , lastName = user.lastName
                    , email = user.email
                    , isSubmitting = False
                }

        Submitted (Ok ( session, UpdateUser.Invalid errors )) ->
            noCmd session { model | isSubmitting = False, errors = errors }

        Submitted (Err Session.Expired) ->
            redirectToLogin session model

        Submitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd session { model | isSubmitting = False }

        AvatarSelected ->
            ( ( model, File.request "avatar" ), session )

        FileReceived data ->
            let
                file =
                    File.init data
            in
                ( ( { model | newAvatar = Just file }, Cmd.none ), session )


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    File.receive FileReceived



-- VIEW


view : Repo -> Model -> Html Msg
view repo ({ errors } as model) =
    div [ class "ml-56 mr-24" ]
        [ div [ class "mx-auto max-w-90 leading-normal py-12" ]
            [ h1 [ class "pb-8 font-extrabold text-4xl" ] [ text "Personal Settings" ]
            , div [ class "flex" ]
                [ div [ class "flex-1 max-w-md" ]
                    [ div [ class "pb-6" ]
                        [ div [ class "flex" ]
                            [ div [ class "flex-1 mr-2" ]
                                [ label [ for "firstName", class "input-label" ] [ text "First Name" ]
                                , input
                                    [ id "firstName"
                                    , type_ "text"
                                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "firstName" errors ) ]
                                    , name "firstName"
                                    , placeholder "Jane"
                                    , value model.firstName
                                    , onInput FirstNameChanged
                                    , disabled model.isSubmitting
                                    ]
                                    []
                                , errorView "firstName" errors
                                ]
                            , div [ class "flex-1" ]
                                [ label [ for "lastName", class "input-label" ] [ text "Last Name" ]
                                , input
                                    [ id "lastName"
                                    , type_ "text"
                                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "lastName" errors ) ]
                                    , name "lastName"
                                    , placeholder "Doe"
                                    , value model.lastName
                                    , onInput LastNameChanged
                                    , disabled model.isSubmitting
                                    ]
                                    []
                                , errorView "lastName" errors
                                ]
                            ]
                        ]
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
                            , disabled model.isSubmitting
                            ]
                            []
                        , errorView "email" errors
                        ]
                    ]
                , div [ class "flex-1" ]
                    [ File.input "avatar" AvatarSelected []
                    ]
                ]
            , button
                [ type_ "submit"
                , class "btn btn-blue"
                , onClick Submit
                , disabled model.isSubmitting
                ]
                [ text "Save Settings" ]
            ]
        ]
