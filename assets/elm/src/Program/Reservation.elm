module Program.Reservation exposing (Model, Msg(..), subscriptions, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onBlur, onClick, onInput)
import Http
import Json.Decode as Decode exposing (decodeString)
import Json.Encode as Encode
import Regex exposing (Regex)
import ValidationError exposing (ValidationError, errorsFor, errorsNotFor)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { csrfToken : String
    , reservationCount : String
    , formState : FormState
    , email : String
    , handle : String
    , errors : List ValidationError
    }


type FormState
    = PreSubmit
    | Submitting
    | PostSubmit


type alias Flags =
    { csrfToken : String
    , reservationCount : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialState flags, Cmd.none )


initialState : Flags -> Model
initialState flags =
    Model flags.csrfToken flags.reservationCount PreSubmit "" "" []



-- UPDATE


type Msg
    = EmailChanged String
    | HandleChanged String
    | Submit
    | Submitted (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EmailChanged value ->
            ( { model | email = value, handle = slugify value }, Cmd.none )

        HandleChanged value ->
            ( { model | handle = value }, Cmd.none )

        Submit ->
            ( { model | formState = Submitting }, submit model )

        Submitted (Ok _) ->
            ( { model | formState = PostSubmit }, Cmd.none )

        Submitted (Err (Http.BadStatus resp)) ->
            case decodeString failureDecoder resp.body of
                Ok value ->
                    ( { model | formState = PreSubmit, errors = value }, Cmd.none )

                Err _ ->
                    ( { model | formState = PreSubmit }, Cmd.none )

        Submitted (Err _) ->
            ( { model | formState = PreSubmit }, Cmd.none )


slugify : String -> String
slugify email =
    email
        |> String.split "@"
        |> List.head
        |> Maybe.withDefault ""
        |> String.toLower
        |> Regex.replace specialCharRegex (\_ -> "-")
        |> Regex.replace paddedDashRegex (\_ -> "")
        |> String.slice 0 20


specialCharRegex : Regex
specialCharRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "[^a-z0-9]+"


paddedDashRegex : Regex
paddedDashRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "(^-|-$)"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


type alias FormField =
    { type_ : String
    , name : String
    , placeholder : String
    , value : String
    , onInput : String -> Msg
    , autofocus : Bool
    }


view : Model -> Html Msg
view model =
    case model.formState of
        PostSubmit ->
            div []
                [ p [ class "mb-6" ]
                    [ span [] [ text "🎉 " ]
                    , strong [] [ text "Sweet! " ]
                    , span [] [ text <| "We'll save the " ]
                    , strong [] [ text <| "@" ++ model.handle ]
                    , span [] [ text " handle for you." ]
                    ]
                , p [ class "mb-6" ]
                    [ text "If you don't mind, it would help us a ton if you share this with your followers. Here's a handy pre-populated tweet for you!" ]
                , a
                    [ href "https://twitter.com/share?ref_src=twsrc%5Etfw"
                    , class "twitter-share-button"
                    , attribute "data-url" "https://level.app"
                    , attribute "data-size" "large"
                    , attribute "data-text" "🔥 I just reserved my handle on Level, a distraction-free alternative to Slack designed for software teams."
                    , attribute "data-related" "PoweredByLevel"
                    , attribute "data-show-count" "false"
                    ]
                    [ text "Tweet" ]
                , script
                    [ attribute "async" ""
                    , src "https://platform.twitter.com/widgets.js"
                    ]
                ]

        _ ->
            formView model


script : List (Attribute msg) -> Html msg
script attributes =
    node "script" attributes []


formView : Model -> Html Msg
formView model =
    div [ class "pb-8" ]
        [ p [ class "mb-6" ]
            [ text "Level is under active development and is not yet launched. However, you can claim your little slice of real estate on level.app." ]
        , p [ class "mb-6" ]
            [ span [] [ text "Join " ]
            , strong [ class "font-bold" ] [ text model.reservationCount ]
            , span [] [ text " other people who have reserved their handle." ]
            ]
        , div [ class "md:flex md:pb-4" ]
            [ div [ class "pb-6 md:pb-0 md:mr-4 flex-grow" ]
                [ label [ for "name", class "input-label text-base" ] [ text "Your Email Address" ]
                , textField (FormField "email" "email" "jane@acme.co" model.email EmailChanged False)
                    (errorsFor "email" model.errors)
                ]
            , div [ class "pb-6 md:pb-0" ]
                [ label [ for "name", class "input-label text-base" ] [ text "Your Handle" ]
                , handleField model.handle (errorsFor "handle" model.errors)
                ]
            ]
        , button
            [ type_ "submit"
            , class "btn btn-blue mb-4"
            , onClick Submit
            , disabled (model.formState == Submitting)
            ]
            [ text "Reserve my handle" ]
        , div [ class "text-base text-dusty-blue" ]
            [ text "I will send out periodic updates to keep you in the loop. No spam, guaranteed!" ]
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
            , autofocus field.autofocus
            , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
            ]
            []
        , formErrors errors
        ]


handleField : String -> List ValidationError -> Html Msg
handleField handle errors =
    let
        classes =
            [ ( "input-field inline-flex items-baseline", True )
            , ( "input-field-error", not (List.isEmpty errors) )
            ]
    in
    div []
        [ label [ classList classes ]
            [ span
                [ for "handle"
                , class "flex-none text-dusty-blue-darker select-none leading-none"
                ]
                [ text "level.app/" ]
            , div [ class "flex-1 leading-none" ]
                [ input
                    [ id "handle"
                    , type_ "text"
                    , class "placeholder-blue w-full p-0 no-outline text-dusty-blue-darker"
                    , name "handle"
                    , placeholder "jane"
                    , value handle
                    , onInput HandleChanged
                    , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                    ]
                    []
                ]
            ]
        , formErrors errors
        ]


formErrors : List ValidationError -> Html Msg
formErrors errors =
    case errors of
        error :: _ ->
            div [ class "form-errors text-base" ] [ text error.message ]

        [] ->
            text ""



-- HTTP


submit : Model -> Cmd Msg
submit model =
    Http.send Submitted (request model)


request : Model -> Http.Request String
request model =
    postWithCsrfToken model.csrfToken "/api/reservations" (buildBody model)


postWithCsrfToken : String -> String -> Http.Body -> Http.Request String
postWithCsrfToken token url body =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-Csrf-Token" token ]
        , url = url
        , body = body
        , expect = Http.expectString
        , timeout = Nothing
        , withCredentials = False
        }


buildBody : Model -> Http.Body
buildBody model =
    Http.jsonBody
        (Encode.object
            [ ( "reservation"
              , Encode.object
                    [ ( "email", Encode.string model.email )
                    , ( "handle", Encode.string model.handle )
                    ]
              )
            ]
        )



-- DECODERS


failureDecoder : Decode.Decoder (List ValidationError)
failureDecoder =
    Decode.field "errors" (Decode.list ValidationError.decoder)
