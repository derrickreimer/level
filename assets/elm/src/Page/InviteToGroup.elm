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
import Route.SpaceUsers exposing (Params(..))
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
    { spaceSlug : String
    , groupId : Id
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
        (Repo.getGroup model.groupId repo)



-- PAGE ATTRIBUTES


title : String
title =
    "Invite to group"



-- LIFECYCLE


init : String -> Id -> Globals -> Task Session.Error ( Globals, Model )
init spaceSlug groupId globals =
    globals.session
        |> InviteToGroupInit.request spaceSlug groupId
        |> Task.map (buildModel spaceSlug groupId globals)


buildModel : String -> Id -> Globals -> ( Session, InviteToGroupInit.Response ) -> ( Globals, Model )
buildModel spaceSlug groupId globals ( newSession, resp ) =
    let
        model =
            Model spaceSlug groupId resp.viewerId resp.spaceId resp.bookmarkIds resp.spaceUserIds

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
                [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text ("Invite to " ++ Group.name data.group) ]
                ]
            , div [ class "pb-8" ]
                [ label [ class "flex items-center p-4 w-full rounded bg-grey-light" ]
                    [ div [ class "flex-0 flex-no-shrink pr-3" ] [ Icons.search ]
                    , input [ id "search-input", type_ "text", class "flex-1 bg-transparent no-outline", placeholder "Type to search" ] []
                    ]
                ]
            , text "TODO"
            ]
        ]
