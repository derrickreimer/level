module Signup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, onBlur)
import Http
import Regex exposing (regex)
import Data.ValidationError exposing (ValidationError, errorDecoder, errorsFor, errorsNotFor)
import Mutation.CreateSpace as CreateSpace
import Session exposing (Session)


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
    { session : Session
    , name : String
    , slug : String
    , errors : List ValidationError
    , lastCheckedSlug : String
    , formState : FormState
    }


type FormState
    = Idle
    | Submitting


type alias Flags =
    { apiToken : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( (initialState flags), Cmd.none )


initialState : Flags -> Model
initialState flags =
    { session = Session.init flags.apiToken
    , name = ""
    , slug = ""
    , errors = []
    , lastCheckedSlug = ""
    , formState = Idle
    }



-- UPDATE


type Msg
    = NameChanged String
    | SlugChanged String
    | Submit
    | Submitted (Result Http.Error CreateSpace.Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NameChanged val ->
            ( { model | name = val, slug = (slugify val) }, Cmd.none )

        SlugChanged val ->
            ( { model | slug = val }, Cmd.none )

        Submit ->
            ( { model | formState = Submitting }, submit model )

        Submitted (Ok (CreateSpace.Success space)) ->
            -- TODO
            ( model, Cmd.none )

        Submitted (Ok (CreateSpace.Invalid errors)) ->
            ( { model | errors = errors, formState = Idle }, Cmd.none )

        Submitted (Err _) ->
            ( { model | formState = Idle }, Cmd.none )


slugify : String -> String
slugify name =
    name
        |> String.toLower
        |> (Regex.replace Regex.All (regex "[^a-z0-9]+") (\_ -> "-"))
        |> (Regex.replace Regex.All (regex "(^-|-$)") (\_ -> ""))
        |> String.slice 0 20



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
    }


view : Model -> Html Msg
view model =
    div [ class "container mx-auto px-4 py-24 flex justify-center max-w-430px" ]
        [ div [ class "w-full" ]
            [ div [ class "mb-8 text-center" ]
                [ img [ src "/images/logo-md.svg", class "logo-md", alt "Level" ] []
                ]
            , div
                [ classList
                    [ ( "px-16 py-8 bg-white rounded-lg border", True )
                    , ( "shake", not (List.isEmpty model.errors) )
                    ]
                ]
                [ h1 [ class "text-center text-2xl font-extrabold text-dusty-blue-darker pb-8" ]
                    [ text "Create a new space" ]
                , div [ class "pb-6" ]
                    [ label [ for "name", class "input-label" ] [ text "Name your space" ]
                    , textField (FormField "text" "name" "Smith, Co." model.name NameChanged)
                        (errorsFor "name" model.errors)
                    ]
                , div [ class "pb-6" ]
                    [ label [ for "slug", class "input-label" ] [ text "Pick your URL" ]
                    , textField (FormField "text" "slug" "smith-co" model.slug SlugChanged)
                        (errorsFor "slug" model.errors)
                    ]
                , button
                    [ type_ "submit"
                    , class "btn btn-blue w-full"
                    , onClick Submit
                    , disabled (model.formState == Submitting)
                    ]
                    [ text "Let's get started" ]
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



-- HTTP


submit : Model -> Cmd Msg
submit model =
    CreateSpace.request (CreateSpace.Params model.name model.slug) model.session
        |> Http.send Submitted
