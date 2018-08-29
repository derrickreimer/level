module Page.NewGroup exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Browser.Navigation as Nav
import Event exposing (Event)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CreateGroup as CreateGroup
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
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


init : String -> Session -> Task Session.Error ( Session, Model )
init spaceSlug session =
    session
        |> SetupInit.request spaceSlug
        |> Task.andThen buildModel


buildModel : ( Session, SetupInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { viewer, space, bookmarks } ) =
    let
        model =
            Model
                viewer
                space
                bookmarks
                ""
                False
                False
                []
    in
    Task.succeed ( session, model )


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


update : Msg -> Session -> Nav.Key -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session navKey model =
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

        Submitted (Ok ( newSession, CreateGroup.Success group )) ->
            let
                redirectTo =
                    Route.Group (Route.Group.Root (Space.getSlug model.space) (Group.getId group))
            in
            ( ( model, Route.pushUrl navKey redirectTo ), newSession )

        Submitted (Ok ( newSession, CreateGroup.Invalid errors )) ->
            ( ( { model | isSubmitting = False, errors = errors }, Cmd.none ), newSession )

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



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarks = insertUniqueBy Group.getId group model.bookmarks }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarks = removeBy Group.getId group model.bookmarks }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    spaceLayout repo
        model.viewer
        model.space
        model.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
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
        ]
