module Page.Inbox exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import FieldEditor exposing (FieldEditor)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import KeyboardShortcuts exposing (Modifier(..))
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.ClosePost as ClosePost
import Mutation.DismissPosts as DismissPosts
import Mutation.MarkAsRead as MarkAsRead
import Pagination
import Post exposing (Post)
import PushManager
import PushStatus exposing (PushStatus)
import Query.InboxInit as InboxInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Response exposing (Response)
import Route exposing (Route)
import Route.Inbox exposing (Params(..))
import Route.Search
import Route.SpaceUser
import Route.SpaceUsers
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import Vendor.Keys as Keys exposing (enter, esc, onKeydown, preventDefault)
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
    "Inbox"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error (Response ( Globals, Model ))
init params globals =
    globals.session
        |> InboxInit.request (InboxInit.variables params)
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.map (afterInit params globals)


afterInit : Params -> Globals -> ( ( Session, Response InboxInit.Data ), ( Zone, Posix ) ) -> Response ( Globals, Model )
afterInit params globals ( ( newSession, resp ), now ) =
    Response.map (buildModel params globals newSession now) resp


buildModel : Params -> Globals -> Session -> ( Zone, Posix ) -> InboxInit.Data -> ( Globals, Model )
buildModel params globals newSession now data =
    let
        postComps =
            Connection.map (buildPostComponent data.spaceId) data.postWithRepliesIds

        model =
            Model
                params
                data.viewerId
                data.spaceId
                data.bookmarkIds
                data.featuredUserIds
                postComps
                now
                (FieldEditor.init "search-editor" "")
                False
                False

        newRepo =
            Repo.union data.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


buildPostComponent : Id -> ( Id, Connection Id ) -> Component.Post.Model
buildPostComponent spaceId ( postId, replyIds ) =
    Component.Post.init spaceId postId replyIds


setup : Globals -> Model -> Cmd Msg
setup globals model =
    let
        postsCmd =
            model.postComps
                |> Connection.toList
                |> setupPostComps globals
    in
    Cmd.batch
        [ postsCmd
        , Scroll.toDocumentTop NoOp
        , markPostsAsRead globals model
        ]


teardown : Globals -> Model -> Cmd Msg
teardown globals model =
    let
        postsCmd =
            model.postComps
                |> Connection.toList
                |> teardownPostComps globals
    in
    postsCmd


setupPostComps : Globals -> List Component.Post.Model -> Cmd Msg
setupPostComps globals comps =
    comps
        |> List.map (\comp -> Cmd.map (PostComponentMsg comp.id) (Component.Post.setup globals comp))
        |> Cmd.batch


teardownPostComps : Globals -> List Component.Post.Model -> Cmd Msg
teardownPostComps globals comps =
    comps
        |> List.map (\comp -> Cmd.map (PostComponentMsg comp.id) (Component.Post.teardown globals comp))
        |> Cmd.batch


markPostsAsRead : Globals -> Model -> Cmd Msg
markPostsAsRead globals model =
    let
        postIds =
            model.postComps
                |> Connection.toList
                |> List.map .postId

        unreadPostIds =
            globals.repo
                |> Repo.getPosts postIds
                |> List.filter (\post -> Post.inboxState post == Post.Unread)
                |> List.map Post.id
    in
    if List.length unreadPostIds > 0 then
        globals.session
            |> MarkAsRead.request model.spaceId unreadPostIds
            |> Task.attempt PostsMarkedAsRead

    else
        Cmd.none



-- UPDATE


type Msg
    = NoOp
    | Tick Posix
    | SetCurrentTime Posix Zone
    | PostsMarkedAsRead (Result Session.Error ( Session, MarkAsRead.Response ))
    | PostComponentMsg String Component.Post.Msg
    | DismissPostsClicked
    | PostsDismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | PushSubscribeClicked
    | PostsRefreshed (Result Session.Error ( Session, Response InboxInit.Data ))
    | ExpandSearchEditor
    | CollapseSearchEditor
    | SearchEditorChanged String
    | SearchSubmitted
    | PostClosed (Result Session.Error ( Session, ClosePost.Response ))
      -- MOBILE
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

        PostsMarkedAsRead (Ok ( newSession, _ )) ->
            let
                newGlobals =
                    { globals | session = newSession }
            in
            ( ( model, Cmd.none ), newGlobals )

        PostsMarkedAsRead _ ->
            noCmd globals model

        PostComponentMsg id componentMsg ->
            case Connection.get .id id model.postComps of
                Just component ->
                    let
                        ( ( newComponent, cmd ), newGlobals ) =
                            Component.Post.update componentMsg globals component
                    in
                    ( ( { model | postComps = Connection.update .id newComponent model.postComps }
                      , Cmd.map (PostComponentMsg id) cmd
                      )
                    , newGlobals
                    )

                Nothing ->
                    noCmd globals model

        DismissPostsClicked ->
            let
                postIds =
                    model.postComps
                        |> filterBySelected
                        |> List.map .id

                cmd =
                    globals.session
                        |> DismissPosts.request model.spaceId postIds
                        |> Task.attempt PostsDismissed
            in
            if List.isEmpty postIds then
                noCmd globals model

            else
                ( ( model, cmd ), globals )

        PostsDismissed (Ok ( newSession, DismissPosts.Success posts )) ->
            let
                ( newModel, cmd ) =
                    if Route.Inbox.getState model.params == Route.Inbox.Undismissed then
                        List.foldr (removePost globals) ( model, Cmd.none ) posts

                    else
                        ( model, Cmd.none )
            in
            ( ( newModel, cmd )
            , { globals
                | flash = Flash.set Flash.Notice "Dismissed from inbox" 3000 globals.flash
              }
            )

        PostsDismissed _ ->
            noCmd globals model

        PushSubscribeClicked ->
            ( ( model, PushManager.subscribe ), globals )

        PostsRefreshed (Ok ( newSession, Response.Found data )) ->
            let
                newPostComps =
                    Connection.map (buildPostComponent model.spaceId) data.postWithRepliesIds

                newRepo =
                    Repo.union data.repo globals.repo

                ( addedComps, removedComps ) =
                    Connection.diff .id newPostComps model.postComps

                setupCmds =
                    setupPostComps globals addedComps

                teardownCmds =
                    teardownPostComps globals removedComps
            in
            ( ( { model | postComps = newPostComps }
              , Cmd.batch [ setupCmds, teardownCmds ]
              )
            , { globals | session = newSession, repo = newRepo }
            )

        PostsRefreshed (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        PostsRefreshed (Err Session.Expired) ->
            redirectToLogin globals model

        PostsRefreshed (Err _) ->
            noCmd globals model

        ExpandSearchEditor ->
            expandSearchEditor globals model

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
                        (Route.Inbox.getSpaceSlug model.params)
                        (FieldEditor.getValue newSearchEditor)

                cmd =
                    Route.pushUrl globals.navKey (Route.Search searchParams)
            in
            ( ( { model | searchEditor = newSearchEditor }, cmd ), globals )

        PostClosed _ ->
            noCmd { globals | flash = Flash.set Flash.Notice "Marked as resolved" 3000 globals.flash } model

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )


refreshPosts : Params -> Globals -> Cmd Msg
refreshPosts params globals =
    globals.session
        |> InboxInit.request (InboxInit.variables params)
        |> Task.attempt PostsRefreshed


expandSearchEditor : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
expandSearchEditor globals model =
    ( ( { model | searchEditor = FieldEditor.expand model.searchEditor }
      , setFocus (FieldEditor.getNodeId model.searchEditor) NoOp
      )
    , globals
    )


removePost : Globals -> Post -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
removePost globals post ( model, cmd ) =
    case Connection.get .id (Post.id post) model.postComps of
        Just postComp ->
            let
                newPostComps =
                    Connection.remove .id (Post.id post) model.postComps

                teardownCmd =
                    Cmd.map (PostComponentMsg postComp.id)
                        (Component.Post.teardown globals postComp)

                newCmd =
                    Cmd.batch [ cmd, teardownCmd ]
            in
            ( { model | postComps = newPostComps }, newCmd )

        Nothing ->
            ( model, cmd )



-- EVENTS


consumeEvent : Event -> Globals -> Model -> ( Model, Cmd Msg )
consumeEvent event globals model =
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

        Event.PostsDismissed posts ->
            if Route.Inbox.getState model.params == Route.Inbox.Undismissed then
                List.foldr (removePost globals) ( model, Cmd.none ) posts

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


consumeKeyboardEvent : Globals -> KeyboardShortcuts.Event -> Model -> ( ( Model, Cmd Msg ), Globals )
consumeKeyboardEvent globals event model =
    case ( event.key, event.modifiers ) of
        ( "/", [] ) ->
            expandSearchEditor globals model

        ( "k", [] ) ->
            let
                newPostComps =
                    Connection.selectPrev model.postComps

                cmd =
                    case Connection.selected newPostComps of
                        Just currentPost ->
                            Scroll.toAnchor Scroll.Document (Component.Post.postNodeId currentPost.postId) 120

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postComps = newPostComps }, cmd ), globals )

        ( "j", [] ) ->
            let
                newPostComps =
                    Connection.selectNext model.postComps

                cmd =
                    case Connection.selected newPostComps of
                        Just currentPost ->
                            Scroll.toAnchor Scroll.Document (Component.Post.postNodeId currentPost.postId) 120

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postComps = newPostComps }, cmd ), globals )

        ( "e", [] ) ->
            case Connection.selected model.postComps of
                Just currentPost ->
                    let
                        cmd =
                            globals.session
                                |> DismissPosts.request model.spaceId [ currentPost.postId ]
                                |> Task.attempt PostsDismissed
                    in
                    ( ( model, cmd ), globals )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "e", [ Meta ] ) ->
            case Connection.selected model.postComps of
                Just currentPost ->
                    let
                        cmd =
                            globals.session
                                |> MarkAsRead.request model.spaceId [ currentPost.postId ]
                                |> Task.attempt PostsMarkedAsRead
                    in
                    ( ( model, cmd ), globals )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "y", [] ) ->
            case Connection.selected model.postComps of
                Just currentPost ->
                    let
                        cmd =
                            globals.session
                                |> ClosePost.request model.spaceId currentPost.postId
                                |> Task.attempt PostClosed
                    in
                    ( ( model, cmd ), globals )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "r", [] ) ->
            case Connection.selected model.postComps of
                Just currentPost ->
                    let
                        ( ( newCurrentPost, compCmd ), newGlobals ) =
                            Component.Post.expandReplyComposer globals currentPost

                        newPostComps =
                            Connection.update .id newCurrentPost model.postComps
                    in
                    ( ( { model | postComps = newPostComps }
                      , Cmd.map (PostComponentMsg currentPost.id) compCmd
                      )
                    , globals
                    )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        _ ->
            ( ( model, Cmd.none ), globals )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ every 1000 Tick
        ]



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
            , showKeyboardCommands = globals.showKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 max-w-lg leading-normal" ]
            [ div [ class "sticky pin-t mb-3 px-4 pt-4 bg-white z-50" ]
                [ div [ class "trans-border-b-grey" ]
                    [ div [ class "flex items-center" ]
                        [ h2 [ class "flex-no-shrink font-bold text-2xl" ] [ text "Inbox" ]
                        , controlsView model data
                        ]
                    , div [ class "flex items-baseline relative -pin-b-1px" ]
                        [ filterTab Device.Desktop "To Do" Route.Inbox.Undismissed (undismissedParams model.params) model.params
                        , filterTab Device.Desktop "Dismissed" Route.Inbox.Dismissed (dismissedParams model.params) model.params
                        ]
                    ]
                ]
            , filterNoticeView globals.repo model data
            , desktopPostsView globals model data
            , Layout.SpaceDesktop.rightSidebar (sidebarView globals data.space data.featuredUsers)
            ]
        ]


desktopPostsView : Globals -> Model -> Data -> Html Msg
desktopPostsView globals model data =
    let
        spaceUsers =
            Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo

        groups =
            Repo.getGroups (Space.groupIds data.space) globals.repo
    in
    if Connection.isEmptyAndExpanded model.postComps then
        div [ class "pt-16 pb-16 font-headline text-center text-lg" ]
            [ text "You’re all caught up!" ]

    else
        div [] <|
            Connection.mapList (desktopPostView globals spaceUsers groups model data) model.postComps


desktopPostView : Globals -> List SpaceUser -> List Group -> Model -> Data -> Component.Post.Model -> Html Msg
desktopPostView globals spaceUsers groups model data component =
    let
        config =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = model.now
            , spaceUsers = spaceUsers
            , groups = groups
            , showGroups = True
            }

        isSelected =
            Connection.selected model.postComps == Just component
    in
    div
        [ classList
            [ ( "relative mb-3 p-4", True )
            ]
        ]
        [ viewIf isSelected <|
            div [ class "absolute w-1 rounded-full pin-t pin-b pin-l bg-dusty-blue" ] []
        , component
            |> Component.Post.view config
            |> Html.map (PostComponentMsg component.id)
        ]


controlsView : Model -> Data -> Html Msg
controlsView model data =
    div [ class "flex items-center flex-grow justify-end" ]
        [ selectionControlsView model.postComps
        , searchEditorView model.searchEditor
        , paginationView model.params model.postComps
        ]


selectionControlsView : Connection Component.Post.Model -> Html Msg
selectionControlsView posts =
    let
        selectedPosts =
            filterBySelected posts
    in
    if List.isEmpty selectedPosts then
        text ""

    else
        div []
            [ selectedLabel selectedPosts
            , button [ class "mr-4 btn btn-xs btn-blue", onClick DismissPostsClicked ] [ text "Dismiss" ]
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


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "Inbox"
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
                [ filterTab Device.Mobile "To Do" Route.Inbox.Undismissed (undismissedParams model.params) model.params
                , filterTab Device.Mobile "Dismissed" Route.Inbox.Dismissed (dismissedParams model.params) model.params
                ]
            , filterNoticeView globals.repo model data
            , div [ class "px-3" ] [ mobilePostsView globals model data ]
            , viewUnless (Connection.isEmptyAndExpanded model.postComps) <|
                div [ class "flex justify-center p-8 pb-16" ]
                    [ paginationView model.params model.postComps
                    ]
            , viewIf model.showSidebar <|
                Layout.SpaceMobile.rightSidebar config
                    [ div [ class "p-6" ] (sidebarView globals data.space data.featuredUsers)
                    ]
            ]
        ]


mobilePostsView : Globals -> Model -> Data -> Html Msg
mobilePostsView globals model data =
    let
        spaceUsers =
            Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo

        groups =
            Repo.getGroups (Space.groupIds data.space) globals.repo
    in
    if Connection.isEmptyAndExpanded model.postComps then
        div [ class "pt-16 pb-16 font-headline text-center text-lg" ]
            [ text "You’re all caught up!" ]

    else
        div [] <|
            Connection.mapList (mobilePostView globals spaceUsers groups model data) model.postComps


mobilePostView : Globals -> List SpaceUser -> List Group -> Model -> Data -> Component.Post.Model -> Html Msg
mobilePostView globals spaceUsers groups model data component =
    let
        config =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = model.now
            , spaceUsers = spaceUsers
            , groups = groups
            , showGroups = True
            }
    in
    div [ class "py-4" ]
        [ component
            |> Component.Post.view config
            |> Html.map (PostComponentMsg component.id)
        ]



-- SHARED


filterTab : Device -> String -> Route.Inbox.State -> Params -> Params -> Html Msg
filterTab device label state linkParams currentParams =
    let
        isCurrent =
            Route.Inbox.getState currentParams == state
    in
    a
        [ Route.href (Route.Inbox linkParams)
        , classList
            [ ( "block text-sm mr-4 py-2 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            , ( "text-center min-w-100px", device == Device.Mobile )
            ]
        ]
        [ text label ]


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (\beforeCursor -> Route.Inbox (Route.Inbox.setCursors (Just beforeCursor) Nothing params))
        (\afterCursor -> Route.Inbox (Route.Inbox.setCursors Nothing (Just afterCursor) params))


filterNoticeView : Repo -> Model -> Data -> Html Msg
filterNoticeView repo model data =
    if Route.Inbox.getLastActivity model.params == Route.Inbox.Today then
        let
            resetParams =
                model.params
                    |> Route.Inbox.setLastActivity Route.Inbox.All
                    |> Route.Inbox.setCursors Nothing Nothing
        in
        div [ class "flex items-center mb-3 py-2 pl-4 pr-2 sm:rounded-full bg-blue text-white text-sm font-bold" ]
            [ div [ class "mr-2 flex-no-shrink" ] [ Icons.filter ]
            , div [ class "flex-grow" ] [ text "Showing activity from today only" ]
            , a
                [ Route.href <| Route.Inbox resetParams
                , class "btn btn-flex btn-xs btn-blue-inverse no-underline flex-no-shrink"
                ]
                [ text "Clear this filter" ]
            ]

    else
        text ""


sidebarView : Globals -> Space -> List SpaceUser -> List (Html Msg)
sidebarView globals space featuredUsers =
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
        , viewUnless (PushStatus.getIsSubscribed globals.pushStatus |> Maybe.withDefault True) <|
            li []
                [ button
                    [ class "text-md text-dusty-blue no-underline font-bold"
                    , onClick PushSubscribeClicked
                    ]
                    [ text "Enable notifications" ]
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


undismissedParams : Params -> Params
undismissedParams params =
    params
        |> Route.Inbox.setCursors Nothing Nothing
        |> Route.Inbox.setState Route.Inbox.Undismissed


dismissedParams : Params -> Params
dismissedParams params =
    params
        |> Route.Inbox.setCursors Nothing Nothing
        |> Route.Inbox.setState Route.Inbox.Dismissed


filterBySelected : Connection Component.Post.Model -> List Component.Post.Model
filterBySelected posts =
    posts
        |> Connection.toList
        |> List.filter .isChecked


selectedLabel : List a -> Html Msg
selectedLabel list =
    let
        count =
            List.length list

        target =
            pluralize count "post" "posts"
    in
    span [ class "mr-2 text-sm text-dusty-blue" ]
        [ text <| String.fromInt count ++ " " ++ target ++ " selected" ]


pluralize : Int -> String -> String -> String
pluralize count singular plural =
    if count == 1 then
        singular

    else
        plural
