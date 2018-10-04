module Page.NewGroup exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Browser.Navigation as Nav
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CreateGroup as CreateGroup
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus)
import View.SpaceLayout



-- MODEL


type alias Model =
    { spaceSlug : String
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , name : String
    , isPrivate : Bool
    , isSubmitting : Bool
    , errors : List ValidationError
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)



-- PAGE PROPERTIES


title : String
title =
    "Create a group"



-- LIFECYCLE


init : String -> Globals -> Task Session.Error ( Globals, Model )
init spaceSlug globals =
    globals.session
        |> SetupInit.request spaceSlug
        |> Task.map (buildModel spaceSlug globals)


buildModel : String -> Globals -> ( Session, SetupInit.Response ) -> ( Globals, Model )
buildModel spaceSlug globals ( newSession, resp ) =
    let
        model =
            Model
                spaceSlug
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                ""
                False
                False
                []

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.batch
        [ setFocus "name" NoOp
        , Scroll.toDocumentTop NoOp
        ]


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


update : Msg -> Globals -> Nav.Key -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals navKey model =
    case msg of
        NameChanged val ->
            noCmd globals { model | name = val }

        Submit ->
            let
                cmd =
                    globals.session
                        |> CreateGroup.request model.spaceId model.name model.isPrivate
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True }, cmd ), globals )

        Submitted (Ok ( newSession, CreateGroup.Success group )) ->
            let
                redirectTo =
                    Route.Group (Route.Group.init model.spaceSlug (Group.id group))
            in
            ( ( model, Route.pushUrl navKey redirectTo ), { globals | session = newSession } )

        Submitted (Ok ( newSession, CreateGroup.Invalid errors )) ->
            ( ( { model | isSubmitting = False, errors = errors }, Cmd.none )
            , { globals | session = newSession }
            )

        Submitted (Err Session.Expired) ->
            redirectToLogin globals model

        Submitted (Err _) ->
            noCmd globals model

        PrivacyToggled ->
            noCmd globals { model | isPrivate = not model.isPrivate }

        NoOp ->
            noCmd globals model


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    case resolveData repo model of
        Just data ->
            resolvedView repo maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> Maybe Route -> Model -> Data -> Html Msg
resolvedView repo maybeCurrentRoute model data =
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
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
