module Page.Settings exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import DigestSettings exposing (DigestSettings)
import Event exposing (Event)
import File exposing (File)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Id exposing (Id)
import Json.Decode as Decode
import ListHelpers exposing (insertUniqueBy, removeBy)
import Minutes
import Mutation.CreateNudge as CreateNudge
import Mutation.DeleteNudge as DeleteNudge
import Mutation.UpdateDigestSettings as UpdateDigestSettings
import Mutation.UpdateSpace as UpdateSpace
import Mutation.UpdateSpaceAvatar as UpdateSpaceAvatar
import Nudge exposing (Nudge)
import Query.SettingsInit as SettingsInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Settings exposing (Params)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, errorsNotFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, onKeydown, preventDefault)
import View.Helpers exposing (viewIf)
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , name : String
    , slug : String
    , digestSettings : DigestSettings
    , nudges : List Nudge
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


nudgeIntervals : List Int
nudgeIntervals =
    List.range 12 36
        |> List.map ((*) 30)



-- PAGE PROPERTIES


title : String
title =
    "Space Settings"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SettingsInit.request (Route.Settings.getSpaceSlug params)
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SettingsInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                (Space.name resp.space)
                (Space.slug resp.space)
                resp.digestSettings
                resp.nudges
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
    Scroll.toDocumentTop NoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp
    | NameChanged String
    | SlugChanged String
    | Submit
    | Submitted (Result Session.Error ( Session, UpdateSpace.Response ))
    | AvatarSubmitted (Result Session.Error ( Session, UpdateSpaceAvatar.Response ))
    | AvatarSelected
    | FileReceived Decode.Value
    | DigestToggled
    | DigestSettingsUpdated (Result Session.Error ( Session, UpdateDigestSettings.Response ))
    | NudgeToggled Int
    | NudgeCreated (Result Session.Error ( Session, CreateNudge.Response ))
    | NudgeDeleted (Result Session.Error ( Session, DeleteNudge.Response ))


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

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
            let
                newGlobals =
                    { globals
                        | session = newSession
                        , flash = Flash.set Flash.Notice "Settings saved" 3000 globals.flash
                    }
            in
            noCmd newGlobals
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

        FileReceived value ->
            case Decode.decodeValue File.decoder value of
                Ok file ->
                    let
                        cmd =
                            case File.getContents file of
                                Just contents ->
                                    globals.session
                                        |> UpdateSpaceAvatar.request model.spaceId contents
                                        |> Task.attempt AvatarSubmitted

                                Nothing ->
                                    Cmd.none
                    in
                    ( ( { model | newAvatar = Just file }, cmd ), globals )

                _ ->
                    noCmd globals model

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Success space )) ->
            noCmd { globals | session = newSession } { model | avatarUrl = Space.avatarUrl space }

        AvatarSubmitted (Ok ( newSession, UpdateSpaceAvatar.Invalid errors )) ->
            noCmd { globals | session = newSession } { model | errors = errors }

        AvatarSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        AvatarSubmitted (Err _) ->
            -- TODO: handle unexpected exceptions
            noCmd globals { model | isSubmitting = False }

        DigestToggled ->
            let
                cmd =
                    globals.session
                        |> UpdateDigestSettings.request model.spaceId (not (DigestSettings.isEnabled model.digestSettings))
                        |> Task.attempt DigestSettingsUpdated
            in
            ( ( { model | digestSettings = DigestSettings.toggle model.digestSettings }, cmd ), globals )

        DigestSettingsUpdated (Ok ( newSession, UpdateDigestSettings.Success newDigestSettings )) ->
            ( ( { model | digestSettings = newDigestSettings, isSubmitting = False }
              , Cmd.none
              )
            , { globals
                | session = newSession
                , flash = Flash.set Flash.Notice "Digest updated" 3000 globals.flash
              }
            )

        DigestSettingsUpdated (Err Session.Expired) ->
            redirectToLogin globals model

        DigestSettingsUpdated _ ->
            -- TODO: handle unexpected exceptions
            noCmd globals { model | isSubmitting = False }

        NudgeToggled minute ->
            let
                cmd =
                    case nudgeAt minute model of
                        Just nudge ->
                            globals.session
                                |> DeleteNudge.request (DeleteNudge.variables model.spaceId (Nudge.id nudge))
                                |> Task.attempt NudgeDeleted

                        Nothing ->
                            globals.session
                                |> CreateNudge.request (CreateNudge.variables model.spaceId minute)
                                |> Task.attempt NudgeCreated
            in
            ( ( model, cmd ), globals )

        NudgeCreated (Ok ( newSession, CreateNudge.Success nudge )) ->
            let
                newNudges =
                    nudge :: model.nudges
            in
            ( ( { model | nudges = newNudges }, Cmd.none )
            , { globals | session = newSession }
            )

        NudgeCreated (Err Session.Expired) ->
            redirectToLogin globals model

        NudgeCreated _ ->
            noCmd globals model

        NudgeDeleted (Ok ( newSession, DeleteNudge.Success nudge )) ->
            let
                newNudges =
                    removeBy Nudge.id nudge model.nudges
            in
            ( ( { model | nudges = newNudges }, Cmd.none )
            , { globals | session = newSession }
            )

        NudgeDeleted (Err Session.Expired) ->
            redirectToLogin globals model

        NudgeDeleted _ ->
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
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto max-w-md leading-normal p-8" ]
            [ div [ class "pb-4" ]
                [ nav [ class "text-xl font-headline font-extrabold text-dusty-blue-dark leading-tight" ] [ text <| Space.name data.space ]
                , h1 [ class "font-extrabold tracking-semi-tight text-3xl" ] [ text "Settings" ]
                ]
            , div [ class "flex items-baseline mb-6 border-b" ]
                [ filterTab "Preferences" Route.Settings.Preferences (Route.Settings.setSection Route.Settings.Preferences model.params) model.params
                , viewIf (Space.canUpdate data.space) <|
                    filterTab "Space Settings" Route.Settings.Space (Route.Settings.setSection Route.Settings.Space model.params) model.params
                ]
            , viewIf (Route.Settings.getSection model.params == Route.Settings.Preferences) <|
                preferencesView model data
            , viewIf (Route.Settings.getSection model.params == Route.Settings.Space) <|
                spaceSettingsView model data
            ]
        ]


preferencesView : Model -> Data -> Html Msg
preferencesView model data =
    div []
        [ nudgesView model data
        , digestsView model data
        ]


digestsView : Model -> Data -> Html Msg
digestsView model data =
    div []
        [ h2 [ class "mb-3 text-dusty-blue-darker text-lg font-extrabold" ] [ text "Digests" ]
        , label [ class "control checkbox pb-6" ]
            [ input
                [ type_ "checkbox"
                , class "checkbox"
                , onClick DigestToggled
                , checked (DigestSettings.isEnabled model.digestSettings)
                , disabled model.isSubmitting
                ]
                []
            , span [ class "control-indicator" ] []
            , span [ class "select-none" ] [ text "Email me a daily digest after 4pm" ]
            ]
        ]


nudgesView : Model -> Data -> Html Msg
nudgesView model data =
    div [ class "mb-16" ]
        [ h2 [ class "mb-2 text-dusty-blue-darker text-lg font-extrabold" ] [ text "Nudges" ]
        , p [ class "mb-3" ] [ text "Choose when to get notified about new activity in your Inbox." ]
        , div [ class "flex flex-no-wrap" ] (List.indexedMap (nudgeTile model) nudgeIntervals)
        ]


nudgeTile : Model -> Int -> Int -> Html Msg
nudgeTile model idx minute =
    let
        isActive =
            hasNudgeAt minute model
    in
    button
        [ classList
            [ ( "mr-1 relative text-center flex-grow rounded h-12 no-outline", True )
            , ( "bg-grey", not isActive )
            , ( "bg-blue", isActive )
            ]
        , onClick (NudgeToggled minute)
        ]
        [ viewIf (modBy 4 idx == 0) <|
            div
                [ class "absolute text-xs text-dusty-blue font-bold pin-l-50"
                , style "bottom" "-20px"
                , style "transform" "translateX(-50%)"
                ]
                [ text (Minutes.toString minute) ]
        , div
            [ class "absolute p-2 text-xs font-bold text-white bg-dusty-blue-darker rounded pin-l-50 tooltip"
            , style "bottom" "-35px"
            , style "transform" "translateX(-50%)"
            ]
            [ text (Minutes.toString minute)
            ]
        ]


spaceSettingsView : Model -> Data -> Html Msg
spaceSettingsView model data =
    div []
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
        , div [ class "pb-6" ]
            [ label [ for "avatar", class "input-label" ] [ text "Logo" ]
            , Avatar.uploader "avatar" model.avatarUrl AvatarSelected
            ]
        , button
            [ type_ "submit"
            , class "btn btn-blue"
            , onClick Submit
            , disabled model.isSubmitting
            ]
            [ text "Save settings" ]
        ]


filterTab : String -> Route.Settings.Section -> Params -> Params -> Html Msg
filterTab label section linkParams currentParams =
    let
        isCurrent =
            Route.Settings.getSection currentParams == section
    in
    a
        [ Route.href (Route.Settings linkParams)
        , classList
            [ ( "block text-sm mr-4 py-2 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            ]
        ]
        [ text label ]



-- HELPERS


hasNudgeAt : Int -> Model -> Bool
hasNudgeAt minute model =
    List.any (\nudge -> Nudge.minute nudge == minute) model.nudges


nudgeAt : Int -> Model -> Maybe Nudge
nudgeAt minute model =
    model.nudges
        |> List.filter (\nudge -> Nudge.minute nudge == minute)
        |> List.head
