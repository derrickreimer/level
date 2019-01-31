module Page.Groups exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import GroupMembership exposing (GroupMembershipState(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BookmarkGroup as BookmarkGroup
import Mutation.SubscribeToGroup as SubscribeToGroup
import Mutation.UnbookmarkGroup as UnbookmarkGroup
import Mutation.UnsubscribeFromGroup as UnsubscribeFromGroup
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
    , groups : Connection Group

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
    "Channels"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> GroupsInit.request params 100
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
                resp.filteredGroups
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
    | ToggleKeyboardCommands
    | ToggleMembership Group
    | SubscribedToGroup (Result Session.Error ( Session, SubscribeToGroup.Response ))
    | UnsubscribedFromGroup (Result Session.Error ( Session, UnsubscribeFromGroup.Response ))
    | Bookmark Group
    | Unbookmark Group
    | Bookmarked (Result Session.Error ( Session, BookmarkGroup.Response ))
    | Unbookmarked (Result Session.Error ( Session, UnbookmarkGroup.Response ))
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        ToggleMembership group ->
            let
                ( newGroup, cmd ) =
                    if Group.membershipState group == NotSubscribed then
                        ( Group.setMembershipState Subscribed group
                        , globals.session
                            |> SubscribeToGroup.request model.spaceId (Group.id group)
                            |> Task.attempt SubscribedToGroup
                        )

                    else
                        ( Group.setMembershipState NotSubscribed group
                        , globals.session
                            |> UnsubscribeFromGroup.request model.spaceId (Group.id group)
                            |> Task.attempt UnsubscribedFromGroup
                        )

                newGroups =
                    Connection.update Group.id newGroup model.groups
            in
            ( ( { model | groups = newGroups }, cmd ), globals )

        UnsubscribedFromGroup (Ok ( newSession, UnsubscribeFromGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group

                newGroups =
                    Connection.update Group.id group model.groups
            in
            ( ( { model | groups = newGroups }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        UnsubscribedFromGroup (Err Session.Expired) ->
            redirectToLogin globals model

        UnsubscribedFromGroup _ ->
            ( ( model, Cmd.none ), globals )

        SubscribedToGroup (Ok ( newSession, SubscribeToGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group

                newGroups =
                    Connection.update Group.id group model.groups
            in
            ( ( { model | groups = newGroups }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        SubscribedToGroup (Err Session.Expired) ->
            redirectToLogin globals model

        SubscribedToGroup _ ->
            ( ( model, Cmd.none ), globals )

        Bookmark group ->
            let
                cmd =
                    globals.session
                        |> BookmarkGroup.request model.spaceId (Group.id group)
                        |> Task.attempt Bookmarked

                newGroups =
                    Connection.update Group.id (Group.setIsBookmarked True group) model.groups
            in
            ( ( { model | groups = newGroups }, cmd ), globals )

        Bookmarked (Ok ( newSession, BookmarkGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group

                newGroups =
                    Connection.update Group.id group model.groups
            in
            ( ( { model | groups = newGroups }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        Bookmarked (Err Session.Expired) ->
            redirectToLogin globals model

        Bookmarked _ ->
            ( ( model, Cmd.none ), globals )

        Unbookmark group ->
            let
                cmd =
                    globals.session
                        |> UnbookmarkGroup.request model.spaceId (Group.id group)
                        |> Task.attempt Unbookmarked

                newGroups =
                    Connection.update Group.id (Group.setIsBookmarked False group) model.groups
            in
            ( ( { model | groups = newGroups }, cmd ), globals )

        Unbookmarked (Ok ( newSession, UnbookmarkGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group

                newGroups =
                    Connection.update Group.id group model.groups
            in
            ( ( { model | groups = newGroups }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        Unbookmarked (Err Session.Expired) ->
            redirectToLogin globals model

        Unbookmarked _ ->
            ( ( model, Cmd.none ), globals )

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



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
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , showKeyboardCommands = globals.showKeyboardCommands
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "flex items-center pb-4" ]
                [ h1 [ class "flex-1 font-bold tracking-semi-tight text-3xl" ] [ text "Channels" ]
                , div [ class "flex-0 flex-no-shrink" ]
                    [ a [ Route.href (Route.NewGroup (Space.slug data.space)), class "btn btn-blue btn-md no-underline" ] [ text "New channel" ]
                    ]
                ]
            , div [ class "flex items-baseline mb-4 border-b" ]
                [ filterTab Device.Desktop "Open" Route.Groups.Open (openParams model.params) model.params
                , filterTab Device.Desktop "Closed" Route.Groups.Closed (closedParams model.params) model.params
                ]
            , groupsView globals.repo model.params data.space model.groups
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
            , title = "Channels"
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
        [ div [ class "flex justify-center items-baseline mb-3 px-3 pt-2 border-b" ]
            [ filterTab Device.Mobile "Open" Route.Groups.Open (openParams model.params) model.params
            , filterTab Device.Mobile "Closed" Route.Groups.Closed (closedParams model.params) model.params
            ]
        , div [ class "p-3" ] [ groupsView globals.repo model.params data.space model.groups ]
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


groupsView : Repo -> Params -> Space -> Connection Group -> Html Msg
groupsView repo params space groups =
    if Connection.isEmpty groups then
        case Route.Groups.getState params of
            Route.Groups.Open ->
                div [ class "p-2 text-center" ]
                    [ text "Wowza! This space does not have any groups yet." ]

            Route.Groups.Closed ->
                div [ class "p-2 text-center" ]
                    [ text "There are no closed groups to show." ]

    else
        div [ class "leading-semi-loose" ]
            [ ul [ class "list-reset" ] (Connection.mapList (groupView space) groups)
            , div [ class "py-4" ] [ paginationView params groups ]
            ]


groupView : Space -> Group -> Html Msg
groupView space group =
    let
        groupRoute =
            Route.Group (Route.Group.init (Space.slug space) (Group.name group))

        checkboxTooltip =
            if Group.membershipState group == Subscribed then
                "Unsubscribe from channel"

            else
                "Subscribe to channel"
    in
    li [ class "flex items-center font-normal font-sans text-lg" ]
        [ label
            [ class "tooltip tooltip-bottom control checkbox"
            , attribute "data-tooltip" checkboxTooltip
            ]
            [ input
                [ type_ "checkbox"
                , class "checkbox"
                , checked (not <| Group.membershipState group == NotSubscribed)
                , onClick (ToggleMembership group)
                ]
                []
            , span [ class "control-indicator mr-1" ] []
            ]
        , a [ Route.href groupRoute, class "flex-1 px-2 text-blue no-underline hover:bg-grey-lighter rounded" ]
            [ text <| "#" ++ Group.name group ]
        , viewIf (Group.isBookmarked group) <|
            button
                [ class "tooltip tooltip-bottom ml-2 flex-0 no-outline"
                , attribute "data-tooltip" "Unbookmark"
                , onClick (Unbookmark group)
                ]
                [ Icons.bookmark Icons.On
                ]
        , viewUnless (Group.isBookmarked group) <|
            button
                [ class "tooltip tooltip-bottom ml-2 flex-0 no-outline"
                , attribute "data-tooltip" "Bookmark"
                , onClick (Bookmark group)
                ]
                [ Icons.bookmark Icons.Off
                ]
        ]


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (\beforeCursor -> Route.Groups (Route.Groups.setCursors (Just beforeCursor) Nothing params))
        (\afterCursor -> Route.Groups (Route.Groups.setCursors Nothing (Just afterCursor) params))



-- HELPERS


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
