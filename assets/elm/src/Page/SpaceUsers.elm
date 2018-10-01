module Page.SpaceUsers exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

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
import Query.SpaceUsersInit as SpaceUsersInit
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
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , spaceUserIds : Connection Id
    }


type alias IndexedUser =
    ( Int, SpaceUser )


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



-- PAGE ATTRIBUTES


title : String
title =
    "Directory"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SpaceUsersInit.request params 20
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SpaceUsersInit.Response ) -> ( Globals, Model )
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
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-sm leading-normal py-8" ]
                [ div [ class "flex items-center pb-5" ]
                    [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text "Directory" ]
                    , div [ class "flex-0 flex-no-shrink" ]
                        [ a
                            [ Route.href (Route.InviteUsers (Route.SpaceUsers.getSpaceSlug model.params))
                            , class "btn btn-blue btn-md no-underline"
                            ]
                            [ text "Invite people" ]
                        ]
                    ]
                , div [ class "pb-8" ]
                    [ label [ class "flex p-4 w-full rounded bg-grey-light" ]
                        [ div [ class "flex-0 flex-no-shrink pr-3" ] [ Icons.search ]
                        , input [ id "search-input", type_ "text", class "flex-1 bg-transparent no-outline", placeholder "Type to search" ] []
                        ]
                    ]
                , usersView repo model.params model.spaceUserIds
                ]
            ]
        ]


usersView : Repo -> Params -> Connection Id -> Html Msg
usersView repo params spaceUserIds =
    let
        spaceUsers =
            Repo.getSpaceUsers (Connection.toList spaceUserIds) repo

        partitions =
            spaceUsers
                |> List.indexedMap Tuple.pair
                |> partitionUsers []
    in
    div [ class "leading-semi-loose" ]
        [ div [] <| List.map userPartitionView partitions
        , paginationView params spaceUserIds
        ]


userPartitionView : ( String, List IndexedUser ) -> Html Msg
userPartitionView ( letter, indexedUsers ) =
    div [ class "flex" ]
        [ div [ class "flex-0 flex-no-shrink pt-1 pl-5 w-12 text-sm text-dusty-blue font-bold" ] [ text letter ]
        , div [ class "flex-1" ] <|
            List.map userView indexedUsers
        ]


userView : IndexedUser -> Html Msg
userView ( index, spaceUser ) =
    div []
        [ h2 [ class "flex items-center pr-4 pb-1 font-normal text-lg" ]
            [ div [ class "mr-4" ] [ SpaceUser.avatar Avatar.Small spaceUser ]
            , text (SpaceUser.displayName spaceUser)
            ]
        ]


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    div [ class "py-4" ]
        [ Pagination.view connection
            (\beforeCursor -> Route.SpaceUsers (Route.SpaceUsers.setCursors (Just beforeCursor) Nothing params))
            (\afterCursor -> Route.SpaceUsers (Route.SpaceUsers.setCursors Nothing (Just afterCursor) params))
        ]



-- HELPERS


partitionUsers : List ( String, List IndexedUser ) -> List IndexedUser -> List ( String, List IndexedUser )
partitionUsers partitions groups =
    case groups of
        hd :: tl ->
            let
                letter =
                    firstLetter (Tuple.second hd)

                ( matches, remaining ) =
                    List.partition (startsWith letter) groups
            in
            partitionUsers (( letter, matches ) :: partitions) remaining

        _ ->
            List.reverse partitions


firstLetter : SpaceUser -> String
firstLetter spaceUser =
    spaceUser
        |> SpaceUser.lastName
        |> String.left 1
        |> String.toUpper


startsWith : String -> IndexedUser -> Bool
startsWith letter ( _, spaceUser ) =
    firstLetter spaceUser == letter


isEven : Int -> Bool
isEven number =
    remainderBy 2 number == 0
