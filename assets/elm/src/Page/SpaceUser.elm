module Page.SpaceUser exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Avatar
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Json.Decode as Decode
import ListHelpers exposing (insertUniqueBy, removeBy)
import Query.SpaceUserInit as SpaceUserInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.SpaceUser exposing (Params)
import Route.SpaceUsers
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import View.Helpers exposing (viewIf)
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , spaceUserId : Id
    , showRevokeModel : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , spaceUser : SpaceUser
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)
        (Repo.getSpaceUser model.spaceUserId repo)



-- PAGE ATTRIBUTES


title : String
title =
    "View user"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SpaceUserInit.request (SpaceUserInit.variables params)
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SpaceUserInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model params resp.viewerId resp.spaceId resp.bookmarkIds resp.spaceUserId False

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
    | ToggleRevokeModel


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        ToggleRevokeModel ->
            ( ( { model | showRevokeModel = not model.showRevokeModel }, Cmd.none ), globals )



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
        [ div [ class "max-w-md mx-auto" ]
            [ detailView model data
            ]
        , viewIf model.showRevokeModel <|
            revokeModal model data
        ]


detailView : Model -> Data -> Html Msg
detailView model data =
    div [ class "px-8 py-6" ]
        [ div [ class "pb-4 mb-6 border-b" ]
            [ a
                [ Route.href <| Route.SpaceUsers (Route.SpaceUsers.init (Route.SpaceUser.getSpaceSlug model.params))
                , class "flex items-center font-bold text-dusty-blue no-underline"
                ]
                [ div [ class "mr-2" ] [ Icons.arrowLeft Icons.On ]
                , div [] [ text "View the member list" ]
                ]
            ]
        , div [ class "flex mb-4 pb-6 border-b" ]
            [ div [ class "flex-no-shrink mr-4" ] [ SpaceUser.avatar Avatar.XLarge data.spaceUser ]
            , div [ class "flex-grow" ]
                [ h1 [ class "mb-1 font-extrabold text-3xl tracking-semi-tight" ] [ text (SpaceUser.displayName data.spaceUser) ]
                , h2 [ class "font-normal text-dusty-blue-dark text-xl" ] [ text <| "@" ++ SpaceUser.handle data.spaceUser ]
                ]
            ]
        , viewIf (Space.canManageMembers data.space) <|
            button
                [ class "flex items-center text-dusty-blue no-underline font-bold"
                , onClick ToggleRevokeModel
                ]
                [ div [ class "mr-2" ] [ Icons.revokeMember ]
                , div [] [ text "Revoke access" ]
                ]
        ]


revokeModal : Model -> Data -> Html Msg
revokeModal model data =
    div
        [ class "fixed pin-l pin-t pin-r pin-b z-50"
        , style "background-color" "rgba(0,0,0,0.5)"
        , onClick ToggleRevokeModel
        ]
        [ div [ class "mx-auto max-w-md px-8 py-24" ]
            [ div
                [ class "px-8 py-6 w-full bg-white rounded shadow-lg leading-normal"
                , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed NoOp))
                ]
                [ h2 [ class "mb-4 font-extrabold text-dusty-blue-darker" ] [ text "Revoke access to this space" ]
                , p [ class "mb-6" ] [ text "Their existing posts will still be accessible to other members of the space, but they will no longer have access." ]
                , button [ class "mr-2 btn btn-blue btn-md" ] [ text <| "Remove " ++ SpaceUser.displayName data.spaceUser ]
                , button [ class "btn btn-grey-outline btn-md", onClick ToggleRevokeModel ] [ text "Cancel" ]
                ]
            ]
        ]


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )
