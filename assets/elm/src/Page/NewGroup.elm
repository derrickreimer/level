module Page.NewGroup
    exposing
        ( Model
        , Msg(..)
        , title
        , init
        , setup
        , teardown
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import Task exposing (Task)
import Data.Space as Space exposing (Space)
import Data.Group as Group exposing (Group)
import Data.ValidationError exposing (ValidationError, errorsFor, isInvalid, errorView)
import Mutation.CreateGroup as CreateGroup
import Route
import Session exposing (Session)
import View.Helpers exposing (setFocus)


-- MODEL


type alias Model =
    { space : Space
    , name : String
    , isPrivate : Bool
    , isSubmitting : Bool
    , errors : List ValidationError
    }



-- PAGE PROPERTIES


title : String
title =
    "Create a group"



-- LIFECYCLE


init : Space -> Task Never Model
init space =
    Task.succeed (buildModel space)


buildModel : Space -> Model
buildModel space =
    Model space "" False False []


setup : Model -> Cmd Msg
setup model =
    setFocus "name" NoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NameChanged String
    | PrivacyToggled
    | Submit
    | Submitted (Result Session.Error ( Session, CreateGroup.Response ))
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        NameChanged val ->
            noCmd session { model | name = val }

        Submit ->
            let
                cmd =
                    session
                        |> CreateGroup.request (Space.getId model.space) model.name model.isPrivate
                        |> Task.attempt Submitted
            in
                ( ( { model | isSubmitting = True }, cmd ), session )

        Submitted (Ok ( session, CreateGroup.Success group )) ->
            ( ( model, Route.newUrl (Route.Group <| Group.getId group) ), session )

        Submitted (Ok ( session, CreateGroup.Invalid errors )) ->
            ( ( { model | isSubmitting = False, errors = errors }, Cmd.none ), session )

        Submitted (Err Session.Expired) ->
            redirectToLogin session model

        Submitted (Err _) ->
            noCmd session model

        PrivacyToggled ->
            noCmd session { model | isPrivate = not model.isPrivate }

        NoOp ->
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-sm leading-normal py-8" ]
            [ div [ class "pb-6" ]
                [ h1 [ class "pb-4 font-extrabold text-3xl" ] [ text "Create a group" ]
                , p [] [ text "Groups are useful for organizing teams within your organization or specific projects that will have ongoing dialogue." ]
                ]
            , div [ class "pb-6" ]
                [ label [ for "name", class "input-label" ] [ text "Name of this group" ]
                , input
                    [ id "name"
                    , type_ "text"
                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "name" model.errors ) ]
                    , name "name"
                    , placeholder "e.g. Engineering"
                    , value model.name
                    , onInput NameChanged
                    , onKeydown preventDefault [ ( [], enter, \_ -> Submit ) ]
                    , disabled model.isSubmitting
                    ]
                    []
                , errorView "name" model.errors
                ]
            , label [ class "control checkbox pb-6" ]
                [ input
                    [ type_ "checkbox"
                    , class "checkbox"
                    , onClick PrivacyToggled
                    , checked model.isPrivate
                    ]
                    []
                , span [ class "control-indicator" ] []
                , span [ class "select-none" ] [ text "Make this group private (invite only)" ]
                ]
            , button
                [ type_ "submit"
                , class "btn btn-blue"
                , onClick Submit
                , disabled model.isSubmitting
                ]
                [ text "Create group" ]
            ]
        ]
