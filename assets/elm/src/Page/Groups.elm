module Page.Groups exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import GroupMembership exposing (GroupMembershipState(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Id exposing (Id)
import Layout.SpaceDesktop
import Layout.SpaceMobile
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



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , groupIds : Connection Id

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
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
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                resp.groupIds
                False
                False

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
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )



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


view : Globals -> Model -> Html Msg
view globals model =
    case resolveData globals.repo model of
        Just data ->
            resolvedView globals model data

        Nothing ->
            text "Something went wrong."


resolvedView : Globals -> Model -> Data -> Html Msg
resolvedView globals model data =
    case globals.device of
        Device.Desktop ->
            resolvedDesktopView globals model data

        Device.Mobile ->
            resolvedMobileView globals model data



-- DESKTOP


resolvedDesktopView : Globals -> Model -> Data -> Html Msg
resolvedDesktopView globals model data =
    let
        config =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "flex items-center pb-4" ]
                [ h1 [ class "flex-1 mx-4 font-bold tracking-semi-tight text-3xl" ] [ text "Groups" ]
                , div [ class "flex-0 flex-no-shrink" ]
                    [ a [ Route.href (Route.NewGroup (Space.slug data.space)), class "btn btn-blue btn-md no-underline" ] [ text "New group" ]
                    ]
                ]
            , div [ class "flex items-baseline mx-4 mb-4 border-b" ]
                [ filterTab Device.Desktop "Open" Route.Groups.Open (openParams model.params) model.params
                , filterTab Device.Desktop "Closed" Route.Groups.Closed (closedParams model.params) model.params
                ]
            , groupsView globals.repo model.params data.space model.groupIds
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "Groups"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
            , rightControl =
                Layout.SpaceMobile.Custom <|
                    a
                        [ class "btn btn-blue btn-md no-underline"
                        , Route.href <| Route.NewGroup (Route.Groups.getSpaceSlug model.params)
                        ]
                        [ text "New" ]
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "mx-auto leading-normal" ]
            [ div [ class "flex justify-center items-baseline mb-3 px-3 pt-2 border-b" ]
                [ filterTab Device.Mobile "Open" Route.Groups.Open (openParams model.params) model.params
                , filterTab Device.Mobile "Closed" Route.Groups.Closed (closedParams model.params) model.params
                ]
            , div [ class "p-2" ] [ groupsView globals.repo model.params data.space model.groupIds ]
            ]
        ]



-- SHARED


filterTab : Device -> String -> Route.Groups.State -> Params -> Params -> Html Msg
filterTab device label state linkParams currentParams =
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
            , ( "text-center min-w-100px", device == Device.Mobile )
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
        case Route.Groups.getState params of
            Route.Groups.Open ->
                div [ class "p-2 text-center" ]
                    [ text "Wowza! This space does not have any groups yet." ]

            Route.Groups.Closed ->
                div [ class "p-2 text-center" ]
                    [ text "There are no closed groups to show." ]

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
    h2 [ class "flex items-center pr-4 font-normal font-sans text-lg" ]
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
