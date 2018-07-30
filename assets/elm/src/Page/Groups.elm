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
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Icons
import Query.GroupsInit as GroupsInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import ViewHelpers exposing (setFocus, viewIf, viewUnless)


-- MODEL


type alias Model =
    { space : Space
    , user : SpaceUser
    , groups : Connection Group
    }


type alias IndexedGroup =
    ( Int, Group )



-- PAGE PROPERTIES


title : String
title =
    "Groups"



-- LIFECYCLE


init : SpaceUser -> Space -> Session -> Task Session.Error ( Session, Model )
init user space session =
    session
        |> GroupsInit.request (Space.getId space) Nothing 10
        |> Task.andThen (buildModel user space)


buildModel : SpaceUser -> Space -> ( Session, GroupsInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space ( session, { groups } ) =
    Task.succeed ( session, Model space user groups )


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
        div [ class "leading-semi-loose" ] <|
            List.map (groupPartitionView repo) partitions


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
                , div [ class "flex-0" ]
                    [ viewIf groupData.isBookmarked <|
                        Icons.bookmark Icons.On
                    , viewUnless groupData.isBookmarked <|
                        Icons.bookmark Icons.Off
                    ]
                ]
            ]



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
