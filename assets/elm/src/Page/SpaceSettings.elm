module Page.SpaceSettings exposing (Model, Msg(..), init, setup, subscriptions, teardown, title, update, view)

import File exposing (File)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
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
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , id : String
    , name : String
    , slug : String
    , avatarUrl : Maybe String
    , errors : List ValidationError
    , isSubmitting : Bool
    , newAvatar : Maybe File
    }



-- PAGE PROPERTIES


title : String
title =
    "Manage this space"



-- LIFECYCLE


init : String -> Session -> Task Session.Error ( Session, Model )
init spaceSlug session =
    session
        |> SetupInit.request spaceSlug
        |> Task.andThen buildModel


buildModel : ( Session, SetupInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { viewer, space, bookmarks } ) =
    let
        spaceData =
            Space.getCachedData space

        model =
            Model
                viewer
                space
                bookmarks
                spaceData.id
                spaceData.name
                spaceData.slug
                spaceData.avatarUrl
                []
                False
                Nothing
    in
    Task.succeed ( session, model )


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


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        NameChanged val ->
            noCmd session { model | name = val }

        SlugChanged val ->
            noCmd session { model | slug = val }

        Submit ->
            let
                cmd =
                    session
                        |> UpdateSpace.request model.id model.name model.slug
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True, errors = [] }, cmd ), session )

        Submitted (Ok ( newSession, UpdateSpace.Success space )) ->
            let
                data =
                    Space.getCachedData space
            in
            noCmd newSession
                { model
                    | name = data.name
                    , slug = data.slug
                    , isSubmitting = False
                }

        Submitted (Ok ( newSession, UpdateSpace.Invalid errors )) ->
            noCmd newSession { model | isSubmitting = False, errors = errors }

        Submitted (Err Session.Expired) ->
            redirectToLogin session model

        Submitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd session { model | isSubmitting = False }

        AvatarSelected ->
            ( ( model, File.request "avatar" ), session )

        FileReceived data ->
            let
                file =
                    File.init data

                cmd =
                    session
                        |> UpdateSpaceAvatar.request model.id (File.getContents file)
                        |> Task.attempt AvatarSubmitted
            in
            ( ( { model | newAvatar = Just file }, cmd ), session )

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Success space )) ->
            let
                data =
                    Space.getCachedData space
            in
            noCmd newSession { model | avatarUrl = data.avatarUrl }

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Invalid errors )) ->
            noCmd newSession { model | errors = errors }

        AvatarSubmitted (Err Session.Expired) ->
            redirectToLogin session model

        AvatarSubmitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd session { model | isSubmitting = False }


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    File.receive FileReceived



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute ({ errors } as model) =
    spaceLayout repo
        model.viewer
        model.space
        model.bookmarks
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
                                , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "name" errors ) ]
                                , name "name"
                                , placeholder "Acme, Co."
                                , value model.name
                                , onInput NameChanged
                                , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                                , disabled model.isSubmitting
                                ]
                                []
                            , errorView "name" errors
                            ]
                        , div [ class "pb-6" ]
                            [ label [ for "slug", class "input-label" ] [ text "URL" ]
                            , div
                                [ classList
                                    [ ( "input-field inline-flex leading-none items-baseline", True )
                                    , ( "input-field-error", isInvalid "slug" errors )
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
                            , errorView "slug" errors
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
