module Program.NewSpace exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, onBlur)
import Regex exposing (regex)
import Task
import Data.ValidationError exposing (ValidationError, isInvalid, errorView)
import Icons
import Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
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



-- LIFECYCLE


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( (buildModel flags), Cmd.none )


buildModel : Flags -> Model
buildModel flags =
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
    | Submitted (Result Session.Error ( Session, CreateSpace.Response ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NameChanged val ->
            ( { model | name = val, slug = (slugify val) }, Cmd.none )

        SlugChanged val ->
            ( { model | slug = val }, Cmd.none )

        Submit ->
            ( { model | formState = Submitting }, submit model )

        Submitted (Ok ( _, CreateSpace.Success _ )) ->
            ( model, Route.toSpace model.slug )

        Submitted (Ok ( _, CreateSpace.Invalid errors )) ->
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
    div [ class "container mx-auto p-8" ]
        [ div [ class "flex pb-16 sm:pb-16 items-center" ]
            [ a [ href "/spaces", class "logo logo-sm" ]
                [ Icons.logo ]
            , div [ class "flex flex-grow justify-start sm:justify-end" ]
                [ a [ href "/manifesto", class "flex-0 ml-6 text-blue no-underline" ] [ text "Manifesto" ] ]
            ]
        , div
            [ classList
                [ ( "mx-auto max-w-sm leading-normal pb-8", True )
                , ( "shake", not (List.isEmpty model.errors) )
                ]
            ]
            [ div [ class "pb-6" ]
                [ h1 [ class "pb-4 font-extrabold text-3xl" ] [ text "Create a space" ]
                , p [] [ text "Spaces represent companies or organizations. Once you create your space, you can invite your colleagues to join." ]
                ]
            , div [ class "pb-6" ]
                [ label [ for "name", class "input-label" ] [ text "Name your space" ]
                , textField (FormField "text" "name" "Smith, Co." model.name NameChanged True) model.errors
                ]
            , div [ class "pb-6" ]
                [ label [ for "slug", class "input-label" ] [ text "Pick your URL" ]
                , slugField model.slug model.errors
                ]
            , button
                [ type_ "submit"
                , class "btn btn-blue"
                , onClick Submit
                , disabled (model.formState == Submitting)
                ]
                [ text "Let's get started" ]
            ]
        ]


textField : FormField -> List ValidationError -> Html Msg
textField field errors =
    let
        classes =
            [ ( "input-field", True )
            , ( "input-field-error", isInvalid field.name errors )
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
            , errorView field.name errors
            ]


slugField : String -> List ValidationError -> Html Msg
slugField slug errors =
    let
        classes =
            [ ( "input-field inline-flex", True )
            , ( "input-field-error", isInvalid "slug" errors )
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
                        , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                        ]
                        []
                    ]
                ]
            , errorView "slug" errors
            ]



-- HTTP


submit : Model -> Cmd Msg
submit model =
    CreateSpace.request model.name model.slug model.session
        |> Task.attempt Submitted
