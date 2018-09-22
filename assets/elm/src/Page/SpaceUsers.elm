module Page.SpaceUsers exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import ListHelpers exposing (insertUniqueBy, removeBy)
import Pagination
import Query.SpaceUsersInit as SpaceUsersInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.SpaceUsers exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import Tuple
import View.Helpers exposing (displayName, viewIf)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , spaceUsers : Connection SpaceUser
    , params : Params
    }


type alias IndexedUser =
    ( Int, SpaceUser )



-- PAGE ATTRIBUTES


title : String
title =
    "Directory"



-- LIFECYCLE


init : Params -> Session -> Task Session.Error ( Session, Model )
init params session =
    session
        |> SpaceUsersInit.request params 20
        |> Task.andThen (buildModel params)


buildModel : Params -> ( Session, SpaceUsersInit.Response ) -> Task Session.Error ( Session, Model )
buildModel params ( session, { viewer, space, bookmarks, spaceUsers } ) =
    Task.succeed ( session, Model viewer space bookmarks spaceUsers params )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


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
            ( { model | bookmarks = insertUniqueBy Group.id group model.bookmarks }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarks = removeBy Group.id group model.bookmarks }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    spaceLayout
        model.viewer
        model.space
        model.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-sm leading-normal py-8" ]
                [ div [ class "flex items-center pb-5" ]
                    [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text "Directory" ]
                    , div [ class "flex-0 flex-no-shrink" ]
                        [ a [ href "#", class "btn btn-blue btn-md no-underline" ] [ text "Invite people" ]
                        ]
                    ]
                , div [ class "pb-8" ]
                    [ label [ class "flex p-4 w-full rounded bg-grey-light" ]
                        [ div [ class "flex-0 flex-no-shrink pr-3" ] [ Icons.search ]
                        , input [ id "search-input", type_ "text", class "flex-1 bg-transparent no-outline", placeholder "Type to search" ] []
                        ]
                    ]
                , usersView repo model.space model.spaceUsers
                ]
            ]
        ]


usersView : Repo -> Space -> Connection SpaceUser -> Html Msg
usersView repo space connection =
    let
        partitions =
            connection
                |> Connection.toList
                |> List.indexedMap Tuple.pair
                |> partitionUsers repo []
    in
    div [ class "leading-semi-loose" ]
        [ div [] <| List.map (userPartitionView repo) partitions
        , paginationView space connection
        ]


userPartitionView : Repo -> ( String, List IndexedUser ) -> Html Msg
userPartitionView repo ( letter, indexedUsers ) =
    div [ class "flex" ]
        [ div [ class "flex-0 flex-no-shrink pt-1 pl-5 w-12 text-sm text-dusty-blue font-bold" ] [ text letter ]
        , div [ class "flex-1" ] <|
            List.map (userView repo) indexedUsers
        ]


userView : Repo -> IndexedUser -> Html Msg
userView repo ( index, spaceUser ) =
    let
        userData =
            Repo.getSpaceUser repo spaceUser
    in
    div []
        [ h2 [ class "flex items-center pr-4 pb-1 font-normal text-lg" ]
            [ div [ class "mr-4" ] [ Avatar.personAvatar Avatar.Small userData ]
            , text (displayName userData)
            ]
        ]


paginationView : Space -> Connection a -> Html Msg
paginationView space connection =
    div [ class "py-4" ]
        [ Pagination.view connection
            (Route.SpaceUsers << Before (Space.slug space))
            (Route.SpaceUsers << After (Space.slug space))
        ]



-- HELPERS


partitionUsers : Repo -> List ( String, List IndexedUser ) -> List IndexedUser -> List ( String, List IndexedUser )
partitionUsers repo partitions groups =
    case groups of
        hd :: tl ->
            let
                letter =
                    firstLetter repo (Tuple.second hd)

                ( matches, remaining ) =
                    List.partition (startsWith repo letter) groups
            in
            partitionUsers repo (( letter, matches ) :: partitions) remaining

        _ ->
            List.reverse partitions


firstLetter : Repo -> SpaceUser -> String
firstLetter repo spaceUser =
    spaceUser
        |> Repo.getSpaceUser repo
        |> .lastName
        |> String.left 1
        |> String.toUpper


startsWith : Repo -> String -> IndexedUser -> Bool
startsWith repo letter ( _, spaceUser ) =
    firstLetter repo spaceUser == letter


isEven : Int -> Bool
isEven number =
    remainderBy 2 number == 0
