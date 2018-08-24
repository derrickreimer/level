module Page.SpaceUsers exposing (Model, Msg(..), init, setup, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Query.SpaceUsersInit as SpaceUsersInit
import Repo exposing (Repo)
import Route
import Route.SpaceUsers exposing (Params)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import Tuple
import View.Helpers exposing (displayName, viewIf)



-- MODEL


type alias Model =
    { space : Space
    , user : SpaceUser
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


init : SpaceUser -> Space -> Params -> Session -> Task Session.Error ( Session, Model )
init user space params session =
    session
        |> SpaceUsersInit.request (Space.getId space) params 20
        |> Task.andThen (buildModel user space params)


buildModel : SpaceUser -> Space -> Params -> ( Session, SpaceUsersInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space params ( session, { spaceUsers } ) =
    Task.succeed ( session, Model space user spaceUsers params )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


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


paginationView : Space -> Connection SpaceUser -> Html Msg
paginationView space connection =
    let
        startCursor =
            Connection.startCursor connection

        endCursor =
            Connection.endCursor connection
    in
    div [ class "flex justify-center p-4" ]
        [ viewIf (Connection.hasPreviousPage connection) (prevButtonView space startCursor)
        , viewIf (Connection.hasNextPage connection) (nextButtonView space endCursor)
        ]


prevButtonView : Space -> Maybe String -> Html Msg
prevButtonView space maybeCursor =
    case maybeCursor of
        Just cursor ->
            let
                route =
                    Route.SpaceUsers (Route.SpaceUsers.Before (Space.getSlug space) cursor)
            in
            a [ Route.href route, class "mx-4" ] [ Icons.arrowLeft ]

        Nothing ->
            text ""


nextButtonView : Space -> Maybe String -> Html Msg
nextButtonView space maybeCursor =
    case maybeCursor of
        Just cursor ->
            let
                route =
                    Route.SpaceUsers (Route.SpaceUsers.After (Space.getSlug space) cursor)
            in
            a [ Route.href route, class "mx-4" ] [ Icons.arrowRight ]

        Nothing ->
            text ""



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
