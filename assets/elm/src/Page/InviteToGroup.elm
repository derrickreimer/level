module Page.InviteToGroup exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Pagination
import Query.InviteToGroupInit as InviteToGroupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.InviteToGroup exposing (Params)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import Tuple
import View.Helpers exposing (viewIf)
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , spaceUserIds : Connection Id
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)
        (Repo.getGroup (Route.InviteToGroup.getGroupId model.params) repo)



-- PAGE ATTRIBUTES


title : String
title =
    "Invite to group"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> InviteToGroupInit.request params
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, InviteToGroupInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model params resp.viewerId resp.spaceId resp.bookmarkIds resp.spaceUserIds

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


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )



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
            [ div [ class "flex items-center pb-5" ]
                [ h1 [ class "flex-1 font-extrabold text-3xl" ] [ text ("Invite people to " ++ Group.name data.group) ]
                ]
            , div [ class "pb-8" ]
                [ p [ class "text-base" ]
                    [ text "Select everyone you would like to invite to the group. They will receive a message in their Level inbox as soon as you click the send button."
                    ]
                ]
            , usersView repo model.spaceUserIds
            , div [ class "pb-4" ]
                [ button [ class "btn btn-blue btn-lg" ] [ text "Send invitations" ] ]
            ]
        ]


usersView : Repo -> Connection Id -> Html Msg
usersView repo connection =
    div [ class "pb-6" ]
        (connection
            |> Connection.toList
            |> List.filterMap (\id -> Repo.getSpaceUser id repo)
            |> List.map userView
        )


userView : SpaceUser -> Html Msg
userView spaceUser =
    div []
        [ label [ class "control checkbox flex items-center pr-4 pb-1 font-normal text-lg select-none" ]
            [ div [ class "flex-0" ]
                [ input
                    [ type_ "checkbox"
                    , class "checkbox"
                    ]
                    []
                , span [ class "control-indicator" ] []
                ]
            , div [ class "mr-3" ] [ SpaceUser.avatar Avatar.Small spaceUser ]
            , text (SpaceUser.displayName spaceUser)
            ]
        ]
