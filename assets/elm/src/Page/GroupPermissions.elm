module Page.GroupPermissions exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Pagination
import Query.GroupPermissionsInit as GroupPermissionsInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.GroupPermissions exposing (Params)
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
    , groupId : Id
    , bookmarkIds : List Id
    , spaceUserIds : Connection Id
    , selectedIds : List Id
    , isSubmitting : Bool
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
        (Repo.getGroup model.groupId repo)



-- PAGE ATTRIBUTES


title : String
title =
    "Invite to group"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> GroupPermissionsInit.request params
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, GroupPermissionsInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model params resp.viewerId resp.spaceId resp.groupId resp.bookmarkIds resp.spaceUserIds [] False

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
    | UserToggled Id


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        UserToggled toggledId ->
            let
                newSelectedIds =
                    if List.member toggledId model.selectedIds then
                        ListHelpers.removeBy identity toggledId model.selectedIds

                    else
                        ListHelpers.insertUniqueBy identity toggledId model.selectedIds
            in
            ( ( { model | selectedIds = newSelectedIds }, Cmd.none ), globals )


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
    let
        groupParams =
            Route.Group.init
                (Route.GroupPermissions.getSpaceSlug model.params)
                (Route.GroupPermissions.getGroupId model.params)
    in
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "pb-3" ]
                [ nav [ class "text-xl font-extrabold leading-tight" ]
                    [ a
                        [ Route.href (Route.Group groupParams)
                        , class "no-underline text-dusty-blue-dark"
                        ]
                        [ text <| Group.name data.group ]
                    ]
                , h1 [ class "flex-1 font-extrabold text-3xl" ] [ text "Permissions" ]
                ]
            , div [ class "pb-6" ]
                [ p [ class "text-base" ]
                    [ text "Manage who is allowed in the group and appoint other owners to help admininstrate it."
                    ]
                ]
            , usersView repo model
            ]
        ]


usersView : Repo -> Model -> Html Msg
usersView repo model =
    div [ class "pb-6" ]
        (model.spaceUserIds
            |> Connection.toList
            |> List.filterMap (\id -> Repo.getSpaceUser id repo)
            |> List.map (userView model)
        )


userView : Model -> SpaceUser -> Html Msg
userView model spaceUser =
    div []
        [ label [ class "control checkbox flex items-center pr-4 pb-1 font-normal text-base select-none" ]
            [ div [ class "flex-0" ]
                [ input
                    [ type_ "checkbox"
                    , class "checkbox"
                    , onClick (UserToggled (SpaceUser.id spaceUser))
                    , checked (List.member (SpaceUser.id spaceUser) model.selectedIds)
                    , disabled model.isSubmitting
                    ]
                    []
                , span [ class "control-indicator" ] []
                ]
            , div [ class "mr-3" ] [ SpaceUser.avatar Avatar.Small spaceUser ]
            , text (SpaceUser.displayName spaceUser)
            ]
        ]



-- INTERNAL


isNotSubmittable : Model -> Bool
isNotSubmittable model =
    List.isEmpty model.selectedIds || model.isSubmitting
