module Program.NewSpace exposing (Model, Msg(..), slugify, subscriptions, update, view)

import Browser exposing (Document)
import Data.User as User exposing (User)
import Data.ValidationError exposing (ValidationError, errorView, isInvalid)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onBlur, onClick, onInput)
import Lazy exposing (Lazy(..))
import Mutation.CreateSpace as CreateSpace
import Query.NewSpaceInit as NewSpaceInit
import Regex exposing (Regex)
import Route
import Session exposing (Session)
import Task
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Layout exposing (userLayout)


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { session : Session
    , user : Lazy User
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
    let
        model =
            buildModel flags
    in
    ( model, setup model )


buildModel : Flags -> Model
buildModel flags =
    { session = Session.init flags.apiToken
    , user = NotLoaded
    , name = ""
    , slug = ""
    , errors = []
    , lastCheckedSlug = ""
    , formState = Idle
    }


setup : Model -> Cmd Msg
setup { session } =
    session
        |> NewSpaceInit.request
        |> Task.attempt InitLoaded



-- UPDATE


type Msg
    = InitLoaded (Result Session.Error ( Session, NewSpaceInit.Response ))
    | NameChanged String
    | SlugChanged String
    | Submit
    | Submitted (Result Session.Error ( Session, CreateSpace.Response ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitLoaded (Ok ( newSession, { user } )) ->
            ( { model | user = Loaded user, session = newSession }, Cmd.none )

        InitLoaded (Err Session.Expired) ->
            ( model, Route.toLogin )

        InitLoaded (Err _) ->
            ( model, Cmd.none )

        NameChanged val ->
            ( { model | name = val, slug = slugify val }, Cmd.none )

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


specialCharRegex : Regex
specialCharRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "[^a-z0-9]+"


paddedDashRegex : Regex
paddedDashRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromString "(^-|-$)"


slugify : String -> String
slugify name =
    name
        |> String.toLower
        |> Regex.replace specialCharRegex (\_ -> "-")
        |> Regex.replace paddedDashRegex (\_ -> "")
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


view : Model -> Document Msg
view model =
    Document "Create a space"
        [ userLayout model.user <|
            div
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
            [ ( "input-field w-full", True )
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
            [ ( "input-field inline-flex leading-none items-baseline", True )
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
