module NewSpace exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, onBlur)
import Http
import Regex exposing (regex)
import Data.ValidationError exposing (ValidationError, errorDecoder, errorsFor, errorsNotFor)
import KeyboardEvents exposing (Modifier(..), enter, onKeyDown, preventDefault)
import Mutation.CreateSpace as CreateSpace
import Route
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
            ( model, Route.toSpace space )

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
    , autofocus : Bool
    }


view : Model -> Html Msg
view model =
    div [ class "bg-grey-lighter h-full min-h-screen" ]
        [ div [ class "container mx-auto px-4 py-24 flex justify-center max-w-400px" ]
            [ div [ class "w-full" ]
                [ div [ class "mb-8 flex justify-center" ]
                    [ img [ src "/images/logo-md.svg", class "logo", alt "Level" ] []
                    ]
                , div
                    [ classList
                        [ ( "px-8 sm:px-12 py-8 bg-white rounded-lg border", True )
                        , ( "shake", not (List.isEmpty model.errors) )
                        ]
                    ]
                    [ h1 [ class "text-center text-2xl font-extrabold text-dusty-blue-darkest pb-8" ]
                        [ text "Create a new space" ]
                    , div [ class "pb-6" ]
                        [ label [ for "name", class "input-label" ] [ text "Name your space" ]
                        , textField (FormField "text" "name" "Smith, Co." model.name NameChanged True)
                            (errorsFor "name" model.errors)
                        ]
                    , div [ class "pb-6" ]
                        [ label [ for "slug", class "input-label" ] [ text "Pick your URL" ]
                        , slugField model.slug (errorsFor "slug" model.errors)
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
                , onKeyDown preventDefault [ ( Unmodified, enter, Submit ) ]
                ]
                []
            , formErrors errors
            ]


slugField : String -> List ValidationError -> Html Msg
slugField slug errors =
    let
        classes =
            [ ( "input-field inline-flex", True )
            , ( "input-field-error", not (List.isEmpty errors) )
            ]
    in
        div []
            [ div [ classList classes ]
                [ label
                    [ for "slug"
                    , class "flex-none text-dusty-blue-darker select-none"
                    ]
                    [ text "level.app/" ]
                , div [ class "flex-1" ]
                    [ input
                        [ id "slug"
                        , type_ "text"
                        , class "placeholder-blue w-full p-0 no-outline text-dusty-blue-darker"
                        , name "slug"
                        , placeholder "smith-co"
                        , value slug
                        , onInput SlugChanged
                        , onKeyDown preventDefault [ ( Unmodified, enter, Submit ) ]
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
            div [ class "form-errors" ] [ text error.message ]

        [] ->
            text ""



-- HTTP


submit : Model -> Cmd Msg
submit model =
    CreateSpace.request (CreateSpace.Params model.name model.slug) model.session
        |> Http.send Submitted
