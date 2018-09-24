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
import NewRepo exposing (NewRepo)
import Pagination
import Query.GroupsInit as GroupsInit
import Route exposing (Route)
import Route.Group
import Route.Groups exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import Tuple
import View.Helpers exposing (setFocus, viewIf, viewUnless)
import View.Layout exposing (spaceLayout)



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


resolveData : NewRepo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (NewRepo.getSpaceUser model.viewerId repo)
        (NewRepo.getSpace model.spaceId repo)
        (Just <| NewRepo.getGroups model.bookmarkIds repo)



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
        newNewRepo =
            NewRepo.union resp.repo globals.newRepo
    in
    ( { globals | session = newSession, newRepo = newNewRepo }
    , Model params resp.viewerId resp.spaceId resp.bookmarkIds resp.groupIds
    )


setup : Model -> Cmd Msg
setup model =
    setFocus "search-input" NoOp


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


view : NewRepo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    case resolveData repo model of
        Just data ->
            resolvedView repo maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : NewRepo -> Maybe Route -> Model -> Data -> Html Msg
resolvedView repo maybeCurrentRoute model data =
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-sm leading-normal py-8" ]
                [ div [ class "flex items-center pb-5" ]
                    [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text "Groups" ]
                    , div [ class "flex-0 flex-no-shrink" ]
                        [ a [ Route.href (Route.NewGroup (Space.slug data.space)), class "btn btn-blue btn-md no-underline" ] [ text "New group" ]
                        ]
                    ]
                , div [ class "pb-8" ]
                    [ label [ class "flex p-4 w-full rounded bg-grey-light" ]
                        [ div [ class "flex-0 flex-no-shrink pr-3" ] [ Icons.search ]
                        , input [ id "search-input", type_ "text", class "flex-1 bg-transparent no-outline", placeholder "Type to search" ] []
                        ]
                    ]
                , groupsView repo data.space model.groupIds
                ]
            ]
        ]


groupsView : NewRepo -> Space -> Connection Id -> Html Msg
groupsView repo space groupIds =
    let
        groups =
            NewRepo.getGroups (Connection.toList groupIds) repo

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
            , paginationView space groupIds
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
            [ a [ Route.href (Route.Group (Route.Group.Root (Space.slug space) (Group.id group))), class "flex-1 text-blue no-underline" ] [ text <| Group.name group ]
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


paginationView : Space -> Connection Id -> Html Msg
paginationView space connection =
    div [ class "py-4" ]
        [ Pagination.view connection
            (Route.Groups << Before (Space.slug space))
            (Route.Groups << After (Space.slug space))
        ]



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
