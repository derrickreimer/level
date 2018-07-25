module Page.SpaceSettings
    exposing
        ( Model
        , Msg(..)
        , init
        , setup
        , teardown
        , update
        , subscriptions
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import Task exposing (Task)
import Data.Space exposing (Space)
import Data.ValidationError exposing (ValidationError, errorsFor, errorsNotFor, isInvalid, errorView)
import File exposing (File)
import Mutation.UpdateSpace as UpdateSpace
import Mutation.UpdateSpaceAvatar as UpdateSpaceAvatar
import Repo exposing (Repo)
import Route
import Session exposing (Session)


-- MODEL


type alias Model =
    { name : String
    , slug : String
    , avatarUrl : Maybe String
    , errors : List ValidationError
    , isSubmitting : Bool
    , newAvatar : Maybe File
    }



-- LIFECYCLE


init : Space -> Task Never Model
init space =
    buildModel space
        |> Task.succeed


buildModel : Space -> Model
buildModel { name, slug } =
    Model name slug Nothing [] False Nothing


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
                        |> UpdateSpace.request model.name model.slug
                        |> Task.attempt Submitted
            in
                ( ( { model | isSubmitting = True, errors = [] }, cmd ), session )

        Submitted (Ok ( session, UpdateSpace.Success space )) ->
            noCmd session
                { model
                    | name = space.name
                    , slug = space.slug
                    , isSubmitting = False
                }

        Submitted (Ok ( session, UpdateSpace.Invalid errors )) ->
            noCmd session { model | isSubmitting = False, errors = errors }

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
                        |> UpdateSpaceAvatar.request (File.getContents file)
                        |> Task.attempt AvatarSubmitted
            in
                ( ( { model | newAvatar = Just file }, cmd ), session )

        AvatarSubmitted (Ok ( session, UpdateSpaceAvatar.Success space )) ->
            noCmd session { model | avatarUrl = space.avatarUrl }

        AvatarSubmitted (Ok ( session, UpdateSpaceAvatar.Invalid errors )) ->
            noCmd session { model | errors = errors }

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


view : Repo -> Model -> Html Msg
view repo ({ errors } as model) =
    div [ class "ml-56 mr-24" ]
        [ div [ class "mx-auto max-w-90 leading-normal py-8" ]
            [ h1 [ class "pb-8 font-extrabold text-4xl" ] [ text "Space Settings" ]
            , div [ class "flex" ]
                [ div [ class "flex-1 mr-16 max-w-sm" ]
                    [ div [ class "pb-6" ]
                        [ label [ for "name", class "input-label" ] [ text "Name of this space" ]
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
                                [ ( "input-field inline-flex", True )
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
                        [ text "Save Settings" ]
                    ]
                , div [ class "flex-0" ]
                    [ File.avatarInput "avatar" model.avatarUrl AvatarSelected
                    ]
                ]
            ]
        ]
