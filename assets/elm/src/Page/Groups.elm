module Page.Groups
    exposing
        ( Model
        , Msg(..)
        , title
        , init
        , setup
        , teardown
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import Data.GroupMembership exposing (GroupMembershipState(..))
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Icons
import Query.GroupsInit as GroupsInit
import Repo exposing (Repo)
import Route
import Route.Groups
import Session exposing (Session)
import ViewHelpers exposing (setFocus, viewIf, viewUnless)


-- MODEL


type alias Model =
    { space : Space
    , user : SpaceUser
    , groups : Connection Group
    , params : Route.Groups.Params
    }


type alias IndexedGroup =
    ( Int, Group )



-- PAGE PROPERTIES


title : String
title =
    "Groups"



-- LIFECYCLE


init : SpaceUser -> Space -> Route.Groups.Params -> Session -> Task Session.Error ( Session, Model )
init user space params session =
    session
        |> GroupsInit.request (Space.getId space) params 20
        |> Task.andThen (buildModel user space params)


buildModel : SpaceUser -> Space -> Route.Groups.Params -> ( Session, GroupsInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space params ( session, { groups } ) =
    Task.succeed ( session, Model space user groups params )


setup : Model -> Cmd Msg
setup model =
    setFocus "search-input" NoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp


update : Msg -> Repo -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg repo session model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), session )



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-sm leading-normal py-8" ]
            [ div [ class "flex items-center pb-5" ]
                [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text "Groups" ]
                , div [ class "flex-0 flex-no-shrink" ]
                    [ a [ Route.href Route.NewGroup, class "btn btn-blue btn-md no-underline" ] [ text "New group" ]
                    ]
                ]
            , div [ class "pb-8" ]
                [ label [ class "flex p-4 w-full rounded bg-grey-light" ]
                    [ div [ class "flex-0 flex-no-shrink pr-3" ] [ Icons.search ]
                    , input [ id "search-input", type_ "text", class "flex-1 bg-transparent no-outline", placeholder "Type to search" ] []
                    ]
                ]
            , groupsView repo model.groups
            ]
        ]


groupsView : Repo -> Connection Group -> Html Msg
groupsView repo connection =
    let
        partitions =
            connection
                |> Connection.toList
                |> List.indexedMap (,)
                |> partitionGroups repo []
    in
        if List.isEmpty partitions then
            div [ class "p-2 text-center" ]
                [ text "Wowza! This space does not have any groups yet." ]
        else
            div [ class "leading-semi-loose" ]
                [ div [] <| List.map (groupPartitionView repo) partitions
                , paginationView connection
                ]


groupPartitionView : Repo -> ( String, List IndexedGroup ) -> Html Msg
groupPartitionView repo ( letter, indexedGroups ) =
    div [ class "flex" ]
        [ div [ class "flex-0 flex-no-shrink pt-1 pl-5 w-12 text-sm text-dusty-blue font-bold" ] [ text letter ]
        , div [ class "flex-1" ] <|
            List.map (groupView repo) indexedGroups
        ]


groupView : Repo -> IndexedGroup -> Html Msg
groupView repo ( index, group ) =
    let
        groupData =
            Repo.getGroup repo group
    in
        div []
            [ h2 [ class "flex items-center pr-4 font-normal text-lg" ]
                [ a [ Route.href (Route.Group groupData.id), class "flex-1 text-blue no-underline" ] [ text groupData.name ]
                , viewIf (groupData.membershipState == Subscribed) <|
                    div [ class "flex-0 mr-4 text-sm text-dusty-blue" ] [ text "Member" ]
                , div [ class "flex-0" ]
                    [ viewIf groupData.isBookmarked <|
                        Icons.bookmark Icons.On
                    , viewUnless groupData.isBookmarked <|
                        Icons.bookmark Icons.Off
                    ]
                ]
            ]


paginationView : Connection Group -> Html Msg
paginationView connection =
    let
        startCursor =
            Connection.startCursor connection

        endCursor =
            Connection.endCursor connection
    in
        div [ class "flex justify-center p-4" ]
            [ viewIf (Connection.hasPreviousPage connection) (prevButtonView startCursor)
            , viewIf (Connection.hasNextPage connection) (nextButtonView endCursor)
            ]


prevButtonView : Maybe String -> Html Msg
prevButtonView maybeCursor =
    case maybeCursor of
        Just cursor ->
            let
                route =
                    Route.Groups (Route.Groups.Before cursor)
            in
                a [ Route.href route, class "mx-4" ] [ Icons.arrowLeft ]

        Nothing ->
            text ""


nextButtonView : Maybe String -> Html Msg
nextButtonView maybeCursor =
    case maybeCursor of
        Just cursor ->
            let
                route =
                    Route.Groups (Route.Groups.After cursor)
            in
                a [ Route.href route, class "mx-4" ] [ Icons.arrowRight ]

        Nothing ->
            text ""



-- HELPERS


partitionGroups : Repo -> List ( String, List IndexedGroup ) -> List IndexedGroup -> List ( String, List IndexedGroup )
partitionGroups repo partitions groups =
    case groups of
        hd :: tl ->
            let
                letter =
                    firstLetter repo (Tuple.second hd)

                ( matches, remaining ) =
                    List.partition (startsWith repo letter) groups
            in
                partitionGroups repo (( letter, matches ) :: partitions) remaining

        _ ->
            List.reverse partitions


firstLetter : Repo -> Group -> String
firstLetter repo group =
    group
        |> Repo.getGroup repo
        |> .name
        |> String.left 1
        |> String.toUpper


startsWith : Repo -> String -> IndexedGroup -> Bool
startsWith repo letter ( _, group ) =
    firstLetter repo group == letter


isEven : Int -> Bool
isEven number =
    rem number 2 == 0
