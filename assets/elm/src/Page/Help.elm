module Page.Help exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Browser.Navigation as Nav
import Clipboard
import Event exposing (Event)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Help exposing (Params)
import Route.WelcomeTutorial
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, viewIf)
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
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
    "Help"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SetupInit.request (Route.Help.getSpaceSlug params)
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SetupInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
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
            [ div [ class "pb-6 text-lg text-dusty-blue-darker" ]
                [ div [ class "mb-6" ]
                    [ h1 [ class "mb-4 font-extrabold tracking-semi-tight text-4xl leading-tight text-dusty-blue-darkest" ] [ text "Help" ]
                    ]
                , ul [ class "list-reset" ]
                    [ li []
                        [ a
                            [ Route.href <| Route.WelcomeTutorial (Route.WelcomeTutorial.init (Route.Help.getSpaceSlug model.params) 1)
                            , class "no-underline"
                            ]
                            [ h2 [ class "block text-2xl text-blue font-extrabold tracking-semi-tight" ] [ text "Welcome to Level" ]
                            , p [ class "text-dusty-blue-dark" ] [ text "A quick tutorial on how Level works." ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
