module Signup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, onBlur)
import Regex exposing (regex)
import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (decodeString)
import Time exposing (Time, second)
import Navigation
import Data.ValidationError exposing (ValidationError, errorDecoder, errorsFor, errorsNotFor)
import Util exposing (postWithCsrfToken)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { csrfToken : String
    , spaceName : String
    , slug : String
    , firstName : String
    , lastName : String
    , username : String
    , email : String
    , password : String
    , errors : List ValidationError
    , lastCheckedSlug : String
    , formState : FormState
    }


type FormState
    = Idle
    | Submitting


type alias Flags =
    { csrfToken : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( (initialState flags), Cmd.none )


initialState : Flags -> Model
initialState flags =
    { csrfToken = flags.csrfToken
    , spaceName = ""
    , slug = ""
    , firstName = ""
    , lastName = ""
    , username = ""
    , email = ""
    , password = ""
    , errors = []
    , lastCheckedSlug = ""
    , formState = Idle
    }



-- UPDATE


type Msg
    = SpaceNameChanged String
    | SlugChanged String
    | UsernameChanged String
    | FirstNameChanged String
    | LastNameChanged String
    | EmailChanged String
    | PasswordChanged String
    | SpaceNameBlurred
    | SlugBlurred
    | UsernameBlurred
    | FirstNameBlurred
    | LastNameBlurred
    | EmailBlurred
    | PasswordBlurred
    | Submit
    | Submitted (Result Http.Error String)
    | Validate
    | Validated String (Result Http.Error (List ValidationError))
    | Tick Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SpaceNameChanged val ->
            ( { model | spaceName = val, slug = (slugify val) }, Cmd.none )

        SlugChanged val ->
            ( { model | slug = val }, Cmd.none )

        FirstNameChanged val ->
            ( { model | firstName = val }, Cmd.none )

        LastNameChanged val ->
            ( { model | lastName = val }, Cmd.none )

        UsernameChanged val ->
            ( { model | username = val }, Cmd.none )

        EmailChanged val ->
            ( { model | email = val }, Cmd.none )

        PasswordChanged val ->
            ( { model | password = val }, Cmd.none )

        SpaceNameBlurred ->
            validateIfPresent model "spaceName" model.spaceName

        SlugBlurred ->
            validateIfPresent model "slug" model.slug

        FirstNameBlurred ->
            validateIfPresent model "firstName" model.firstName

        LastNameBlurred ->
            validateIfPresent model "lastName" model.lastName

        UsernameBlurred ->
            validateIfPresent model "username" model.username

        EmailBlurred ->
            validateIfPresent model "email" model.email

        PasswordBlurred ->
            validateIfPresent model "password" model.password

        Submit ->
            ( { model | formState = Submitting }, submit model )

        Submitted (Ok redirectUrl) ->
            ( model, Navigation.load redirectUrl )

        Submitted (Err (Http.BadStatus resp)) ->
            case decodeString failureDecoder resp.body of
                Ok value ->
                    ( { model | formState = Idle, errors = value }, Cmd.none )

                Err _ ->
                    ( { model | formState = Idle }, Cmd.none )

        Submitted (Err _) ->
            ( { model | formState = Idle }, Cmd.none )

        Validate ->
            ( model, Cmd.none )

        Validated attribute (Ok errors) ->
            let
                newErrors =
                    (errorsFor attribute errors)
                        ++ (errorsNotFor attribute model.errors)
            in
                ( { model | errors = newErrors }, Cmd.none )

        Validated _ (Err _) ->
            ( model, Cmd.none )

        Tick _ ->
            if not (model.slug == "") && not (model.slug == model.lastCheckedSlug) then
                ( { model | lastCheckedSlug = model.slug }, validate "slug" model )
            else
                ( model, Cmd.none )


validateIfPresent : Model -> String -> String -> ( Model, Cmd Msg )
validateIfPresent model attribute value =
    if not (value == "") then
        ( model, validate attribute model )
    else
        ( model, Cmd.none )


slugify : String -> String
slugify spaceName =
    spaceName
        |> String.toLower
        |> (Regex.replace Regex.All (regex "[^a-z0-9]+") (\_ -> "-"))
        |> (Regex.replace Regex.All (regex "(^-|-$)") (\_ -> ""))
        |> String.slice 0 20



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every second Tick



-- VIEW


type alias FormField =
    { type_ : String
    , name : String
    , label : String
    , value : String
    , onInput : String -> Msg
    , onBlur : Msg
    }


view : Model -> Html Msg
view model =
    div [ class "signup-form" ]
        [ div [ class "signup-form__header" ]
            [ h1 [ class "signup-form__heading" ] [ text "Join Level" ]
            , p [ class "signup-form__description" ] [ text "Level is a smarter communication platform built for teams that value their focus. Take it for a spin!" ]
            ]
        , div [ class "signup-form__section" ]
            [ div [ class "signup-form__section-header" ]
                [ span [ class "signup-form__section-number" ] [ text "1" ]
                , text "Tell us about yourself!"
                ]
            , div [ class "signup-form__section-body" ]
                [ div [ class "inline-field-group" ]
                    [ textField (FormField "text" "first_name" "First Name" model.firstName FirstNameChanged FirstNameBlurred) (errorsFor "first_name" model.errors)
                    , textField (FormField "text" "last_name" "Last Name" model.lastName LastNameChanged LastNameBlurred) (errorsFor "last_name" model.errors)
                    ]
                , textField (FormField "text" "username" "Username" model.username UsernameChanged UsernameBlurred) (errorsFor "username" model.errors)
                , textField (FormField "email" "email" "Email Address" model.email EmailChanged EmailBlurred) (errorsFor "email" model.errors)
                , textField (FormField "password" "password" "Password" model.password PasswordChanged PasswordBlurred) (errorsFor "password" model.errors)
                ]
            ]
        , div [ class "signup-form__section" ]
            [ div [ class "signup-form__section-header" ]
                [ span [ class "signup-form__section-number" ] [ text "2" ]
                , text "Configure your space"
                ]
            , div [ class "signup-form__section-body" ]
                [ textField (FormField "text" "space_name" "Space Name" model.spaceName SpaceNameChanged SpaceNameBlurred) (errorsFor "space_name" model.errors)
                , slugField (FormField "text" "slug" "URL" model.slug SlugChanged SlugBlurred) (errorsFor "slug" model.errors)
                ]
            ]
        , div [ class "signup-form__controls" ]
            [ button
                [ type_ "submit"
                , class "button button--primary button--full button--large"
                , onClick Submit
                , disabled (model.formState == Submitting)
                ]
                [ text "Sign up" ]
            ]
        , div [ class "signup-form__footer" ]
            [ p []
                [ text "Already have a space? "
                , a [ href "/spaces/search" ] [ text "Sign in" ]
                , text "."
                ]
            ]
        ]


textField : FormField -> List ValidationError -> Html Msg
textField field errors =
    div [ class (String.join " " [ "form-field", (errorClass errors) ]) ]
        [ label [ for field.name, class "form-label" ] [ text field.label ]
        , input
            [ id field.name
            , type_ field.type_
            , class "text-field text-field--full text-field--large"
            , name field.name
            , value field.value
            , onInput field.onInput
            , onBlur field.onBlur
            ]
            []
        , formErrors errors
        ]


slugField : FormField -> List ValidationError -> Html Msg
slugField field errors =
    div [ class (String.join " " [ "form-field", (errorClass errors) ]) ]
        [ label [ for "slug", class "form-label" ] [ text "URL" ]
        , div [ class "slug-field" ]
            [ div [ class "slug-field__slug" ]
                [ input
                    [ id field.name
                    , type_ field.type_
                    , class "text-field text-field--large"
                    , name field.name
                    , value field.value
                    , onInput field.onInput
                    , onBlur field.onBlur
                    ]
                    []
                ]
            , div [ class "slug-field__domain" ] [ text ".level.live" ]
            ]
        , formErrors errors
        ]


errorClass : List ValidationError -> String
errorClass errors =
    case errors of
        [] ->
            ""

        _ ->
            "form-field--error"


formErrors : List ValidationError -> Html Msg
formErrors errors =
    case errors of
        error :: _ ->
            div [ class "form-errors" ] [ text error.message ]

        [] ->
            text ""



-- HTTP


submit : Model -> Cmd Msg
submit model =
    Http.send Submitted (buildSubmitRequest model)


validate : String -> Model -> Cmd Msg
validate attribute model =
    Http.send (Validated attribute) (buildValidationRequest model)


buildSubmitRequest : Model -> Http.Request String
buildSubmitRequest model =
    postWithCsrfToken model.csrfToken "/api/spaces" (buildBody model) successDecoder


buildValidationRequest : Model -> Http.Request (List ValidationError)
buildValidationRequest model =
    postWithCsrfToken model.csrfToken "/api/signup/errors" (buildBody model) failureDecoder


buildBody : Model -> Http.Body
buildBody model =
    Http.jsonBody
        (Encode.object
            [ ( "signup"
              , Encode.object
                    [ ( "space_name", Encode.string model.spaceName )
                    , ( "slug", Encode.string model.slug )
                    , ( "first_name", Encode.string model.firstName )
                    , ( "last_name", Encode.string model.lastName )
                    , ( "username", Encode.string model.username )
                    , ( "email", Encode.string model.email )
                    , ( "password", Encode.string model.password )
                    ]
              )
            ]
        )



-- DECODERS


successDecoder : Decode.Decoder String
successDecoder =
    Decode.at [ "redirect_url" ] Decode.string


failureDecoder : Decode.Decoder (List ValidationError)
failureDecoder =
    Decode.field "errors" (Decode.list errorDecoder)
