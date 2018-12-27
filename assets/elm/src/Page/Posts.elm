module Page.Posts exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import FieldEditor exposing (FieldEditor)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import KeyboardShortcuts
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Pagination
import Post exposing (Post)
import Query.PostsInit as PostsInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Posts exposing (Params(..))
import Route.Search
import Route.SpaceUser
import Route.SpaceUsers
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import SpaceUserLists exposing (SpaceUserLists)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import View.Helpers exposing (setFocus, smartFormatTime, viewIf, viewUnless)
import View.SearchBox



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , featuredUserIds : List Id
    , postComps : Connection Component.Post.Model
    , now : ( Zone, Posix )
    , searchEditor : FieldEditor String

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)
        (Just <| Repo.getSpaceUsers model.featuredUserIds repo)



-- PAGE PROPERTIES


title : String
title =
    "Activity"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> PostsInit.request params
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( ( Session, PostsInit.Response ), ( Zone, Posix ) ) -> ( Globals, Model )
buildModel params globals ( ( newSession, resp ), now ) =
    let
        postComps =
            Connection.map (buildPostComponent params) resp.postWithRepliesIds

        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                resp.featuredUserIds
                postComps
                now
                (FieldEditor.init "search-editor" "")
                False
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


buildPostComponent : Params -> ( Id, Connection Id ) -> Component.Post.Model
buildPostComponent params ( postId, replyIds ) =
    Component.Post.init
        Component.Post.Feed
        True
        (Route.Posts.getSpaceSlug params)
        postId
        replyIds


setup : Model -> Cmd Msg
setup model =
    let
        postsCmd =
            model.postComps
                |> Connection.toList
                |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.setup c))
                |> Cmd.batch
    in
    Cmd.batch
        [ postsCmd
        , Scroll.toDocumentTop NoOp
        ]


teardown : Model -> Cmd Msg
teardown model =
    let
        postsCmd =
            model.postComps
                |> Connection.toList
                |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.teardown c))
                |> Cmd.batch
    in
    postsCmd



-- UPDATE


type Msg
    = NoOp
    | Tick Posix
    | SetCurrentTime Posix Zone
    | PostComponentMsg String Component.Post.Msg
    | ExpandSearchEditor
    | CollapseSearchEditor
    | SearchEditorChanged String
    | SearchSubmitted
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), globals )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
                |> noCmd globals

        PostComponentMsg id componentMsg ->
            case Connection.get .id id model.postComps of
                Just component ->
                    let
                        ( ( newComponent, cmd ), newGlobals ) =
                            Component.Post.update componentMsg model.spaceId globals component
                    in
                    ( ( { model | postComps = Connection.update .id newComponent model.postComps }
                      , Cmd.map (PostComponentMsg id) cmd
                      )
                    , newGlobals
                    )

                Nothing ->
                    noCmd globals model

        ExpandSearchEditor ->
            ( ( { model | searchEditor = FieldEditor.expand model.searchEditor }
              , setFocus (FieldEditor.getNodeId model.searchEditor) NoOp
              )
            , globals
            )

        CollapseSearchEditor ->
            ( ( { model | searchEditor = FieldEditor.collapse model.searchEditor }
              , Cmd.none
              )
            , globals
            )

        SearchEditorChanged newValue ->
            ( ( { model | searchEditor = FieldEditor.setValue newValue model.searchEditor }
              , Cmd.none
              )
            , globals
            )

        SearchSubmitted ->
            let
                newSearchEditor =
                    model.searchEditor
                        |> FieldEditor.setIsSubmitting True

                searchParams =
                    Route.Search.init
                        (Route.Posts.getSpaceSlug model.params)
                        (FieldEditor.getValue newSearchEditor)

                cmd =
                    Route.pushUrl globals.navKey (Route.Search searchParams)
            in
            ( ( { model | searchEditor = newSearchEditor }, cmd ), globals )

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.ReplyCreated reply ->
            let
                postId =
                    Reply.postId reply
            in
            case Connection.get .id postId model.postComps of
                Just component ->
                    let
                        ( newComponent, cmd ) =
                            Component.Post.handleReplyCreated reply component
                    in
                    ( { model | postComps = Connection.update .id newComponent model.postComps }
                    , Cmd.map (PostComponentMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ every 1000 Tick
        , KeyboardShortcuts.subscribe
            [ ( "/", ExpandSearchEditor )
            ]
        ]



-- VIEW


view : Globals -> Model -> Html Msg
view globals model =
    let
        spaceUsers =
            SpaceUserLists.resolveList globals.repo model.spaceId globals.spaceUserLists
    in
    case resolveData globals.repo model of
        Just data ->
            resolvedView globals spaceUsers model data

        Nothing ->
            text "Something went wrong."


resolvedView : Globals -> List SpaceUser -> Model -> Data -> Html Msg
resolvedView globals spaceUsers model data =
    case globals.device of
        Device.Desktop ->
            resolvedDesktopView globals spaceUsers model data

        Device.Mobile ->
            resolvedMobileView globals spaceUsers model data



-- DESKTOP


resolvedDesktopView : Globals -> List SpaceUser -> Model -> Data -> Html Msg
resolvedDesktopView globals spaceUsers model data =
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
        [ div [ class "mx-auto px-8 max-w-lg leading-normal" ]
            [ div [ class "sticky pin-t trans-border-b-grey mb-3 pt-4 bg-white z-50" ]
                [ div [ class "flex items-center" ]
                    [ h2 [ class "flex-no-shrink font-bold text-2xl" ] [ text "Activity" ]
                    , controlsView model
                    ]
                , div [ class "flex items-baseline" ]
                    [ filterTab Device.Desktop "Open" Route.Posts.Open (openParams model.params) model.params
                    , filterTab Device.Desktop "Resolved" Route.Posts.Closed (closedParams model.params) model.params
                    ]
                ]
            , postsView globals spaceUsers model data
            , Layout.SpaceDesktop.rightSidebar (sidebarView data.space data.featuredUsers)
            ]
        ]


desktopFilterTab : String -> Route.Posts.State -> Params -> Params -> Html Msg
desktopFilterTab label state linkParams currentParams =
    let
        isCurrent =
            Route.Posts.getState currentParams == state
    in
    a
        [ Route.href (Route.Posts linkParams)
        , classList
            [ ( "block text-sm mr-4 py-2 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            ]
        ]
        [ text label ]


controlsView : Model -> Html Msg
controlsView model =
    div [ class "flex flex-grow justify-end" ]
        [ searchEditorView model.searchEditor
        , paginationView model.params model.postComps
        ]


searchEditorView : FieldEditor String -> Html Msg
searchEditorView editor =
    View.SearchBox.view
        { editor = editor
        , changeMsg = SearchEditorChanged
        , expandMsg = ExpandSearchEditor
        , collapseMsg = CollapseSearchEditor
        , submitMsg = SearchSubmitted
        }



-- MOBILE


resolvedMobileView : Globals -> List SpaceUser -> Model -> Data -> Html Msg
resolvedMobileView globals spaceUsers model data =
    let
        config =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "Activity"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
            , rightControl = Layout.SpaceMobile.ShowSidebar
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "mx-auto leading-normal" ]
            [ div [ class "flex justify-center items-baseline mb-3 px-3 pt-2 border-b" ]
                [ filterTab Device.Mobile "Open" Route.Posts.Open (openParams model.params) model.params
                , filterTab Device.Mobile "Resolved" Route.Posts.Closed (closedParams model.params) model.params
                ]
            , div [ class "px-4" ] [ postsView globals spaceUsers model data ]
            , viewUnless (Connection.isEmptyAndExpanded model.postComps) <|
                div [ class "flex justify-center p-8 pb-16" ]
                    [ paginationView model.params model.postComps
                    ]
            , viewIf model.showSidebar <|
                Layout.SpaceMobile.rightSidebar config
                    [ div [ class "p-6" ] (sidebarView data.space data.featuredUsers)
                    ]
            ]
        ]



-- SHARED


filterTab : Device -> String -> Route.Posts.State -> Params -> Params -> Html Msg
filterTab device label state linkParams currentParams =
    let
        isCurrent =
            Route.Posts.getState currentParams == state
    in
    a
        [ Route.href (Route.Posts linkParams)
        , classList
            [ ( "block text-sm mr-4 py-2 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            , ( "text-center min-w-100px", device == Device.Mobile )
            ]
        ]
        [ text label ]


postsView : Globals -> List SpaceUser -> Model -> Data -> Html Msg
postsView globals spaceUsers model data =
    if Connection.isEmptyAndExpanded model.postComps then
        div [ class "pt-16 pb-16 font-headline text-center text-lg" ]
            [ text "You're all caught up!" ]

    else
        div [] <|
            Connection.mapList (postView globals spaceUsers model data) model.postComps


postView : Globals -> List SpaceUser -> Model -> Data -> Component.Post.Model -> Html Msg
postView globals spaceUsers model data component =
    let
        config =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = model.now
            , spaceUsers = spaceUsers
            }
    in
    div [ class "py-4" ]
        [ component
            |> Component.Post.view config
            |> Html.map (PostComponentMsg component.id)
        ]


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (\beforeCursor -> Route.Posts (Route.Posts.setCursors (Just beforeCursor) Nothing params))
        (\afterCursor -> Route.Posts (Route.Posts.setCursors Nothing (Just afterCursor) params))


sidebarView : Space -> List SpaceUser -> List (Html Msg)
sidebarView space featuredUsers =
    [ h3 [ class "mb-2 text-base font-bold" ]
        [ a
            [ Route.href (Route.SpaceUsers <| Route.SpaceUsers.init (Space.slug space))
            , class "flex items-center text-dusty-blue-darkest no-underline"
            ]
            [ text "Team Members"
            ]
        ]
    , div [ class "pb-4" ] <| List.map (userItemView space) featuredUsers
    , ul [ class "list-reset" ]
        [ li []
            [ a
                [ Route.href (Route.InviteUsers (Space.slug space))
                , class "text-md text-dusty-blue no-underline font-bold"
                ]
                [ text "Invite people" ]
            ]
        ]
    ]


userItemView : Space -> SpaceUser -> Html Msg
userItemView space user =
    a
        [ Route.href <| Route.SpaceUser (Route.SpaceUser.init (Space.slug space) (SpaceUser.id user))
        , class "flex items-center pr-4 mb-px no-underline text-dusty-blue-darker"
        ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Tiny user ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| SpaceUser.displayName user ]
        ]



-- INTERNAL


openParams : Params -> Params
openParams params =
    params
        |> Route.Posts.setCursors Nothing Nothing
        |> Route.Posts.setState Route.Posts.Open


closedParams : Params -> Params
closedParams params =
    params
        |> Route.Posts.setCursors Nothing Nothing
        |> Route.Posts.setState Route.Posts.Closed
