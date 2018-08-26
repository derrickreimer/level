module Page.UserSettings exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Event exposing (Event)
import File exposing (File)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Lazy exposing (Lazy(..))
import Mutation.UpdateUser as UpdateUser
import Mutation.UpdateUserAvatar as UpdateUserAvatar
import Query.UserSettingsInit as UserSettingsInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import User exposing (User)
import ValidationError exposing (ValidationError, errorView, errorsFor, errorsNotFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Layout exposing (userLayout)



-- MODEL


type alias Model =
    { viewer : User
    , firstName : String
    , lastName : String
    , handle : String
    , email : String
    , avatarUrl : Maybe String
    , errors : List ValidationError
    , isSubmitting : Bool
    , newAvatar : Maybe File
    }



-- PAGE PROPERTIES


title : String
title =
    "User Settings"



-- LIFECYCLE


init : Session -> Task Session.Error ( Session, Model )
init session =
    session
        |> UserSettingsInit.request
        |> Task.andThen buildModel


buildModel : ( Session, UserSettingsInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { user } ) =
    let
        userData =
            User.getCachedData user

        model =
            Model
                user
                userData.firstName
                userData.lastName
                userData.handle
                userData.email
                userData.avatarUrl
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
    = EmailChanged String
    | FirstNameChanged String
    | LastNameChanged String
    | HandleChanged String
    | Submit
    | Submitted (Result Session.Error ( Session, UpdateUser.Response ))
    | AvatarSubmitted (Result Session.Error ( Session, UpdateUserAvatar.Response ))
    | AvatarSelected
    | FileReceived File.Data


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        EmailChanged val ->
            noCmd session { model | email = val }

        FirstNameChanged val ->
            noCmd session { model | firstName = val }

        LastNameChanged val ->
            noCmd session { model | lastName = val }

        HandleChanged val ->
            noCmd session { model | handle = val }

        Submit ->
            let
                cmd =
                    session
                        |> UpdateUser.request model.firstName model.lastName model.handle model.email
                        |> Task.attempt Submitted
            in
            ( ( { model | isSubmitting = True, errors = [] }, cmd ), session )

        Submitted (Ok ( newSession, UpdateUser.Success user )) ->
            let
                userData =
                    User.getCachedData user
            in
            noCmd newSession
                { model
                    | firstName = userData.firstName
                    , lastName = userData.lastName
                    , handle = userData.handle
                    , email = userData.email
                    , isSubmitting = False
                }

        Submitted (Ok ( newSession, UpdateUser.Invalid errors )) ->
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
                        |> UpdateUserAvatar.request (File.getContents file)
                        |> Task.attempt AvatarSubmitted
            in
            ( ( { model | newAvatar = Just file }, cmd ), session )

        AvatarSubmitted (Ok ( newSession, UpdateUserAvatar.Success user )) ->
            let
                userData =
                    User.getCachedData user
            in
            noCmd newSession { model | avatarUrl = userData.avatarUrl }

        AvatarSubmitted (Ok ( newSession, UpdateUserAvatar.Invalid errors )) ->
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



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    File.receive FileReceived



-- VIEW


view : Repo -> Model -> Html Msg
view repo ({ viewer, errors } as model) =
    userLayout (Loaded viewer) <|
        div [ class "mx-auto max-w-md leading-normal" ]
            [ h1 [ class "pb-8 font-extrabold text-4xl" ] [ text "User Settings" ]
            , div [ class "flex" ]
                [ div [ class "flex-1 mr-8" ]
                    [ div [ class "pb-6" ]
                        [ div [ class "flex" ]
                            [ div [ class "flex-1 mr-2" ]
                                [ label [ for "firstName", class "input-label" ] [ text "First Name" ]
                                , input
                                    [ id "firstName"
                                    , type_ "text"
                                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "firstName" errors ) ]
                                    , name "firstName"
                                    , placeholder "Jane"
                                    , value model.firstName
                                    , onInput FirstNameChanged
                                    , onKeydown preventDefault [ ( [], enter, \_ -> Submit ) ]
                                    , disabled model.isSubmitting
                                    ]
                                    []
                                , errorView "firstName" errors
                                ]
                            , div [ class "flex-1" ]
                                [ label [ for "lastName", class "input-label" ] [ text "Last Name" ]
                                , input
                                    [ id "lastName"
                                    , type_ "text"
                                    , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "lastName" errors ) ]
                                    , name "lastName"
                                    , placeholder "Doe"
                                    , value model.lastName
                                    , onInput LastNameChanged
                                    , onKeydown preventDefault [ ( [], enter, \_ -> Submit ) ]
                                    , disabled model.isSubmitting
                                    ]
                                    []
                                , errorView "lastName" errors
                                ]
                            ]
                        ]
                    , div [ class "pb-6" ]
                        [ label [ for "handle", class "input-label" ] [ text "Handle" ]
                        , div
                            [ classList
                                [ ( "input-field inline-flex leading-none items-baseline", True )
                                , ( "input-field-error", isInvalid "handle" errors )
                                ]
                            ]
                            [ label
                                [ for "handle"
                                , class "mr-1 flex-none text-dusty-blue-darker select-none font-extrabold"
                                ]
                                [ text "@" ]
                            , div [ class "flex-1" ]
                                [ input
                                    [ id "handle"
                                    , type_ "text"
                                    , class "placeholder-blue w-full p-0 no-outline text-dusty-blue-darker"
                                    , name "handle"
                                    , placeholder "janesmith"
                                    , value model.handle
                                    , onInput HandleChanged
                                    , onKeydown preventDefault [ ( [], enter, \event -> Submit ) ]
                                    , disabled model.isSubmitting
                                    ]
                                    []
                                ]
                            ]
                        , errorView "handle" errors
                        ]
                    , div [ class "pb-6" ]
                        [ label [ for "email", class "input-label" ] [ text "Email address" ]
                        , input
                            [ id "email"
                            , type_ "email"
                            , classList [ ( "input-field", True ), ( "input-field-error", isInvalid "email" errors ) ]
                            , name "email"
                            , placeholder "jane@acmeco.com"
                            , value model.email
                            , onInput EmailChanged
                            , onKeydown preventDefault [ ( [], enter, \_ -> Submit ) ]
                            , disabled model.isSubmitting
                            ]
                            []
                        , errorView "email" errors
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
