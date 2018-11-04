module Page.Groups exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import GroupMembership exposing (GroupMembershipState(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Pagination
import Query.GroupsInit as GroupsInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.Groups exposing (Params(..))
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import Tuple
import View.Helpers exposing (setFocus, viewIf, viewUnless)
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , groupIds : Connection Id
    }


type alias IndexedGroup =
    ( Int, Group )


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
    "Groups"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> GroupsInit.request params 20
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, GroupsInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model params resp.viewerId resp.spaceId resp.bookmarkIds resp.groupIds

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }
    , model
    )


setup : Model -> Cmd Msg
setup model =
    Cmd.batch
        [ setFocus "search-input" NoOp
        , Scroll.toDocumentTop NoOp
        ]


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
            [ div [ class "flex items-center pb-4" ]
                [ h1 [ class "flex-1 mx-4 font-extrabold text-3xl" ] [ text "Groups" ]
                , div [ class "flex-0 flex-no-shrink" ]
                    [ a [ Route.href (Route.NewGroup (Space.slug data.space)), class "btn btn-blue btn-md no-underline" ] [ text "New group" ]
                    ]
                ]
            , div [ class "flex items-baseline mx-4 mb-4 border-b" ]
                [ filterTab "Open" Route.Groups.Open (openParams model.params) model.params
                , filterTab "Closed" Route.Groups.Closed (closedParams model.params) model.params
                ]
            , groupsView repo model.params data.space model.groupIds
            ]
        ]


filterTab : String -> Route.Groups.State -> Params -> Params -> Html Msg
filterTab label state linkParams currentParams =
    let
        isCurrent =
            Route.Groups.getState currentParams == state
    in
    a
        [ Route.href (Route.Groups linkParams)
        , classList
            [ ( "block text-sm mr-4 py-2 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            ]
        ]
        [ text label ]


groupsView : Repo -> Params -> Space -> Connection Id -> Html Msg
groupsView repo params space groupIds =
    let
        groups =
            Repo.getGroups (Connection.toList groupIds) repo

        partitions =
            groups
                |> List.indexedMap Tuple.pair
                |> partitionGroups []
    in
    if List.isEmpty partitions then
        div [ class "p-2 text-center" ]
            [ text "Wowza! This space does not have any groups yet." ]

    else
        div [ class "leading-semi-loose" ]
            [ div [] <| List.map (groupPartitionView space) partitions
            , div [ class "py-4" ] [ paginationView params groupIds ]
            ]


groupPartitionView : Space -> ( String, List IndexedGroup ) -> Html Msg
groupPartitionView space ( letter, indexedGroups ) =
    div [ class "flex" ]
        [ div [ class "flex-0 flex-no-shrink pt-1 pl-5 w-12 text-sm text-dusty-blue font-bold" ] [ text letter ]
        , div [ class "flex-1" ] <|
            List.map (groupView space) indexedGroups
        ]


groupView : Space -> IndexedGroup -> Html Msg
groupView space ( index, group ) =
    div []
        [ h2 [ class "flex items-center pr-4 font-normal text-lg" ]
            [ a [ Route.href (Route.Group (Route.Group.init (Space.slug space) (Group.id group))), class "flex-1 text-blue no-underline" ] [ text <| Group.name group ]
            , viewIf (Group.membershipState group == Subscribed) <|
                div [ class "flex-0 mr-4 text-sm text-dusty-blue" ] [ text "Member" ]
            , div [ class "flex-0" ]
                [ viewIf (Group.isBookmarked group) <|
                    Icons.bookmark Icons.On
                , viewUnless (Group.isBookmarked group) <|
                    Icons.bookmark Icons.Off
                ]
            ]
        ]


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (\beforeCursor -> Route.Groups (Route.Groups.setCursors (Just beforeCursor) Nothing params))
        (\afterCursor -> Route.Groups (Route.Groups.setCursors Nothing (Just afterCursor) params))



-- HELPERS


partitionGroups : List ( String, List IndexedGroup ) -> List IndexedGroup -> List ( String, List IndexedGroup )
partitionGroups partitions groups =
    case groups of
        hd :: tl ->
            let
                letter =
                    firstLetter (Tuple.second hd)

                ( matches, remaining ) =
                    List.partition (startsWith letter) groups
            in
            partitionGroups (( letter, matches ) :: partitions) remaining

        _ ->
            List.reverse partitions


firstLetter : Group -> String
firstLetter group =
    group
        |> Group.name
        |> String.left 1
        |> String.toUpper


startsWith : String -> IndexedGroup -> Bool
startsWith letter ( _, group ) =
    firstLetter group == letter


isEven : Int -> Bool
isEven number =
    remainderBy 2 number == 0


openParams : Params -> Params
openParams params =
    params
        |> Route.Groups.setCursors Nothing Nothing
        |> Route.Groups.setState Route.Groups.Open


closedParams : Params -> Params
closedParams params =
    params
        |> Route.Groups.setCursors Nothing Nothing
        |> Route.Groups.setState Route.Groups.Closed
