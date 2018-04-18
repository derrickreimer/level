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
    | FirstNameChanged String
    | LastNameChanged String
    | EmailChanged String
    | PasswordChanged String
    | SpaceNameBlurred
    | SlugBlurred
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
    , placeholder : String
    , value : String
    , onInput : String -> Msg
    , onBlur : Msg
    }


view : Model -> Html Msg
view model =
    div [ class "container mx-auto px-4 py-24 flex justify-center" ]
        [ div []
            [ div [ class "mb-8 text-center" ]
                [ img [ src "/images/logo-md.svg", class "logo-md", alt "Level" ] []
                ]
            , div
                [ classList
                    [ ( "px-16 py-8 bg-white rounded-lg border max-w-430px", True )
                    , ( "shake", not (List.isEmpty model.errors) )
                    ]
                ]
                [ h1 [ class "text-center text-2xl font-extrabold text-dusty-blue-darker pb-8" ]
                    [ text "Create a new space" ]
                , div [ class "pb-6" ]
                    [ label [ for "first_name", class "input-label" ] [ text "Your name" ]
                    , div [ class "flex" ]
                        [ div [ class "flex-1 mr-2" ]
                            [ textField (FormField "text" "first_name" "Jane" model.firstName FirstNameChanged FirstNameBlurred)
                                (errorsFor "first_name" model.errors)
                            ]
                        , div [ class "flex-1" ]
                            [ textField (FormField "text" "last_name" "Smith" model.lastName LastNameChanged LastNameBlurred)
                                (errorsFor "last_name" model.errors)
                            ]
                        ]
                    ]
                , div [ class "pb-6" ]
                    [ label [ for "email", class "input-label" ] [ text "Email address" ]
                    , textField (FormField "email" "email" "jane@smithco.com" model.email EmailChanged EmailBlurred)
                        (errorsFor "email" model.errors)
                    ]
                , div [ class "pb-6" ]
                    [ label [ for "space_name", class "input-label" ] [ text "Name of your organization" ]
                    , textField (FormField "text" "space_name" "Smith, Co." model.spaceName SpaceNameChanged SpaceNameBlurred)
                        (errorsFor "space_name" model.errors)
                    ]
                , button
                    [ type_ "submit"
                    , class "btn btn-blue w-full"
                    , onClick Submit
                    , disabled (model.formState == Submitting)
                    ]
                    [ text "Let's get started" ]
                ]
            , div [ class "px-16 pt-6 pb-24 text-sm text-dusty-blue-dark text-center" ]
                [ text "Already have a space? "
                , a [ href "/spaces/search", class "text-blue" ] [ text "Sign in" ]
                ]
            ]
        ]


textField : FormField -> List ValidationError -> Html Msg
textField field errors =
    let
        classes =
            [ ( "input-field", True )
            , ( "input-field-error", not (List.isEmpty errors) )
            ]
    in
        div []
            [ input
                [ id field.name
                , type_ field.type_
                , classList classes
                , name field.name
                , placeholder field.placeholder
                , value field.value
                , onInput field.onInput
                , onBlur field.onBlur
                ]
                []
            , formErrors errors
            ]


formErrors : List ValidationError -> Html Msg
formErrors errors =
    case errors of
        error :: _ ->
            div [ class "text-sm font-bold text-red mt-2" ] [ text error.message ]

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
