module Page.SpaceSettings exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Event exposing (Event)
import File exposing (File)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.UpdateSpace as UpdateSpace
import Mutation.UpdateSpaceAvatar as UpdateSpaceAvatar
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, errorsNotFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { spaceSlug : String
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , name : String
    , slug : String
    , avatarUrl : Maybe String
    , errors : List ValidationError
    , isSubmitting : Bool
    , newAvatar : Maybe File
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
    "Manage this space"



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
                (Space.name resp.space)
                (Space.slug resp.space)
                (Space.avatarUrl resp.space)
                []
                False
                Nothing

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
    = NameChanged String
    | SlugChanged String
    | Submit
    | Submitted (Result Session.Error ( Session, UpdateSpace.Response ))
    | AvatarSubmitted (Result Session.Error ( Session, UpdateSpaceAvatar.Response ))
    | AvatarSelected
    | FileReceived File.Data


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NameChanged val ->
            noCmd globals { model | name = val }

        SlugChanged val ->
            noCmd globals { model | slug = val }

        Submit ->
            let
                cmd =
                    globals.session
                        |> UpdateSpace.request model.spaceId model.name model.slug
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True, errors = [] }, cmd ), globals )

        Submitted (Ok ( newSession, UpdateSpace.Success space )) ->
            noCmd { globals | session = newSession }
                { model
                    | name = Space.name space
                    , slug = Space.slug space
                    , isSubmitting = False
                }

        Submitted (Ok ( newSession, UpdateSpace.Invalid errors )) ->
            noCmd { globals | session = newSession } { model | isSubmitting = False, errors = errors }

        Submitted (Err Session.Expired) ->
            redirectToLogin globals model

        Submitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd globals { model | isSubmitting = False }

        AvatarSelected ->
            ( ( model, File.request "avatar" ), globals )

        FileReceived data ->
            let
                file =
                    File.init data

                cmd =
                    globals.session
                        |> UpdateSpaceAvatar.request model.spaceId (File.getContents file)
                        |> Task.attempt AvatarSubmitted
            in
            ( ( { model | newAvatar = Just file }, cmd ), globals )

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Success space )) ->
            let
                data =
                    Space.getCachedData space
            in
            noCmd { globals | session = newSession } { model | avatarUrl = data.avatarUrl }

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Invalid errors )) ->
            noCmd { globals | session = newSession } { model | errors = errors }

        AvatarSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        AvatarSubmitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd globals { model | isSubmitting = False }


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



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    File.receive FileReceived



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    case resolveData repo model of
        Just data ->
            resolvedView maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Maybe Route -> Model -> Data -> Html Msg
resolvedView maybeCurrentRoute model data =
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "ml-56 mr-24" ]
            [ div [ class "mx-auto max-w-md leading-normal py-8" ]
                [ h1 [ class "pb-8 font-extrabold text-4xl" ] [ text "Space Settings" ]
                , div [ class "flex" ]
                    [ div [ class "flex-1 mr-8" ]
                        [ div [ class "pb-6" ]
                            [ label [ for "name", class "input-label" ] [ text "Space Name" ]
                            , input
                                [ id "name"
                                , type_ "text"
                                , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "name" model.errors ) ]
                                , name "name"
                                , placeholder "Acme, Co."
                                , value model.name
                                , onInput NameChanged
                                , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                                , disabled model.isSubmitting
                                ]
                                []
                            , errorView "name" model.errors
                            ]
                        , div [ class "pb-6" ]
                            [ label [ for "slug", class "input-label" ] [ text "URL" ]
                            , div
                                [ classList
                                    [ ( "input-field inline-flex leading-none items-baseline", True )
                                    , ( "input-field-error", isInvalid "slug" model.errors )
                                    ]
                                ]
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
                                        , value model.slug
                                        , onInput SlugChanged
                                        , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                                        , disabled model.isSubmitting
                                        ]
                                        []
                                    ]
                                ]
                            , errorView "slug" model.errors
                            ]
                        , button
                            [ type_ "submit"
                            , class "btn btn-blue"
                            , onClick Submit
                            , disabled model.isSubmitting
                            ]
                            [ text "Save settings" ]
                        ]
                    , div [ class "flex-0" ]
                        [ File.avatarInput "avatar" model.avatarUrl AvatarSelected
                        ]
                    ]
                ]
            ]
        ]
