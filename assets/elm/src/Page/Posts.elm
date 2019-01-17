module Page.Posts exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import FieldEditor exposing (FieldEditor)
import File exposing (File)
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
import Mutation.CreatePost as CreatePost
import Mutation.DismissPosts as DismissPosts
import Mutation.MarkAsRead as MarkAsRead
import Pagination
import Post exposing (Post)
import PostEditor exposing (PostEditor)
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
    , postComposer : PostEditor
    , isSubmitting : Bool

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
    "Feed"



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
            Connection.map (buildPostComponent resp.spaceId) resp.postWithRepliesIds

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
                (PostEditor.init "post-composer")
                False
                False
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


buildPostComponent : Id -> ( Id, Connection Id ) -> Component.Post.Model
buildPostComponent spaceId ( postId, replyIds ) =
    Component.Post.init spaceId postId replyIds


setup : Globals -> Model -> Cmd Msg
setup globals model =
    let
        setupPostsCmd =
            model.postComps
                |> Connection.toList
                |> List.map (\comp -> Cmd.map (PostComponentMsg comp.id) (Component.Post.setup globals comp))
                |> Cmd.batch
    in
    Cmd.batch
        [ setupPostsCmd
        , Scroll.toDocumentTop NoOp
        ]


teardown : Globals -> Model -> Cmd Msg
teardown globals model =
    let
        teardownPostsCmd =
            model.postComps
                |> Connection.toList
                |> List.map (\comp -> Cmd.map (PostComponentMsg comp.id) (Component.Post.teardown globals comp))
                |> Cmd.batch
    in
    teardownPostsCmd



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | Tick Posix
    | SetCurrentTime Posix Zone
    | PostComponentMsg String Component.Post.Msg
    | ExpandSearchEditor
    | CollapseSearchEditor
    | SearchEditorChanged String
    | SearchSubmitted
    | PostsDismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | PostsMarkedAsRead (Result Session.Error ( Session, MarkAsRead.Response ))
    | PostClosed (Result Session.Error ( Session, ClosePost.Response ))
    | PostEditorEventReceived Decode.Value
    | NewPostBodyChanged String
    | NewPostFileAdded File
    | NewPostFileUploadProgress Id Int
    | NewPostFileUploaded Id Id String
    | NewPostFileUploadError Id
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, CreatePost.Response ))
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

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
                            Component.Post.update componentMsg globals component
                    in
                    ( ( { model | postComps = Connection.update .id newComponent model.postComps }
                      , Cmd.map (PostComponentMsg id) cmd
                      )
                    , newGlobals
                    )

                Nothing ->
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
                        (Route.Posts.getSpaceSlug model.params)
                        (FieldEditor.getValue newSearchEditor)

                cmd =
                    Route.pushUrl globals.navKey (Route.Search searchParams)
            in
            ( ( { model | searchEditor = newSearchEditor }, cmd ), globals )

        PostsDismissed _ ->
            noCmd { globals | flash = Flash.set Flash.Notice "Dismissed from inbox" 3000 globals.flash } model

        PostsMarkedAsRead _ ->
            noCmd { globals | flash = Flash.set Flash.Notice "Moved to inbox" 3000 globals.flash } model

        PostClosed _ ->
            noCmd { globals | flash = Flash.set Flash.Notice "Marked as resolved" 3000 globals.flash } model

        PostEditorEventReceived value ->
            case PostEditor.decodeEvent value of
                PostEditor.LocalDataFetched id body ->
                    if id == PostEditor.getId model.postComposer then
                        let
                            newPostComposer =
                                PostEditor.setBody body model.postComposer
                        in
                        ( ( { model | postComposer = newPostComposer }
                          , Cmd.none
                          )
                        , globals
                        )

                    else
                        noCmd globals model

                PostEditor.Unknown ->
                    noCmd globals model

        NewPostBodyChanged value ->
            let
                newPostComposer =
                    PostEditor.setBody value model.postComposer
            in
            ( ( { model | postComposer = newPostComposer }
              , PostEditor.saveLocal newPostComposer
              )
            , globals
            )

        NewPostFileAdded file ->
            noCmd globals { model | postComposer = PostEditor.addFile file model.postComposer }

        NewPostFileUploadProgress clientId percentage ->
            noCmd globals { model | postComposer = PostEditor.setFileUploadPercentage clientId percentage model.postComposer }

        NewPostFileUploaded clientId fileId url ->
            let
                newPostComposer =
                    model.postComposer
                        |> PostEditor.setFileState clientId (File.Uploaded fileId url)

                cmd =
                    newPostComposer
                        |> PostEditor.insertFileLink fileId
            in
            ( ( { model | postComposer = newPostComposer }, cmd ), globals )

        NewPostSubmit ->
            if PostEditor.isSubmittable model.postComposer then
                let
                    variables =
                        CreatePost.variablesWithoutGroup
                            model.spaceId
                            (PostEditor.getBody model.postComposer)
                            (PostEditor.getUploadIds model.postComposer)

                    cmd =
                        globals.session
                            |> CreatePost.request variables
                            |> Task.attempt NewPostSubmitted
                in
                ( ( { model | postComposer = PostEditor.setToSubmitting model.postComposer }, cmd ), globals )

            else
                noCmd globals model

        NewPostSubmitted (Ok ( newSession, CreatePost.Success newPost )) ->
            let
                newRepo =
                    Repo.setPost newPost globals.repo

                newGlobals =
                    { globals | session = newSession, repo = newRepo }

                ( newPostComposer, postComposerCmd ) =
                    model.postComposer
                        |> PostEditor.reset

                newPostComp =
                    buildPostComponent model.spaceId ( Post.id newPost, Connection.empty )

                postSetupCmd =
                    Cmd.map (PostComponentMsg newPostComp.id) (Component.Post.setup newGlobals newPostComp)

                newPostComps =
                    Connection.prepend .id newPostComp model.postComps
            in
            ( ( { model | postComposer = newPostComposer, postComps = newPostComps }
              , Cmd.batch [ postComposerCmd, postSetupCmd ]
              )
            , newGlobals
            )

        NewPostSubmitted (Ok ( newSession, CreatePost.Invalid _ )) ->
            { model | postComposer = PostEditor.setNotSubmitting model.postComposer }
                |> noCmd { globals | session = newSession }

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewPostSubmitted (Err _) ->
            { model | postComposer = PostEditor.setNotSubmitting model.postComposer }
                |> noCmd globals

        NewPostFileUploadError clientId ->
            noCmd globals { model | postComposer = PostEditor.setFileState clientId File.UploadError model.postComposer }

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


expandSearchEditor : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
expandSearchEditor globals model =
    ( ( { model | searchEditor = FieldEditor.expand model.searchEditor }
      , setFocus (FieldEditor.getNodeId model.searchEditor) NoOp
      )
    , globals
    )


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
                            Scroll.toAnchor Scroll.Document (Component.Post.postNodeId currentPost.postId) 85

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
                            Scroll.toAnchor Scroll.Document (Component.Post.postNodeId currentPost.postId) 85

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
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 max-w-xl leading-normal" ]
            [ div [ class "sticky pin-t mb-3 px-4 pt-2 bg-white z-40" ]
                [ -- div [ class "flex items-center" ]
                  --  [ h2 [ class "flex-no-shrink font-bold text-2xl" ] [ text "Feed" ]
                  --  , controlsView model
                  --  ]
                  div [ class "flex items-center trans-border-b-grey" ]
                    [ div [ class "pt-2 flex-grow flex" ]
                        [ filterTab Device.Desktop "Open" Route.Posts.Open (openParams model.params) model.params
                        , filterTab Device.Desktop "Resolved" Route.Posts.Closed (closedParams model.params) model.params
                        ]
                    , controlsView model
                    ]
                ]

            -- , desktopPostComposerView globals model data
            -- , viewIf (not (String.contains "#" (PostEditor.getBody model.postComposer))) <|
            --     div [ classList [ ( "mr-4 text-right text-sm text-dusty-blue-dark", True ) ] ]
            --         [ span [ class "-mt-1 mr-2 inline-block align-middle" ] [ Icons.hash ]
            --         , text "Hashtag one or more Channels in your post."
            --         ]
            , desktopPostsView globals model data

            -- , Layout.SpaceDesktop.rightSidebar (sidebarView data.space data.featuredUsers)
            ]
        ]


desktopPostComposerView : Globals -> Model -> Data -> Html Msg
desktopPostComposerView globals model data =
    let
        editor =
            model.postComposer

        config =
            { editor = editor
            , spaceId = Space.id data.space
            , spaceUsers = Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo
            , groups = Repo.getGroups (Space.groupIds data.space) globals.repo
            , onFileAdded = NewPostFileAdded
            , onFileUploadProgress = NewPostFileUploadProgress
            , onFileUploaded = NewPostFileUploaded
            , onFileUploadError = NewPostFileUploadError
            , classList = []
            }
    in
    PostEditor.wrapper config
        [ label [ class "composer mb-4" ]
            [ div [ class "flex" ]
                [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Medium data.viewer ]
                , div [ class "flex-grow pl-2 pt-2" ]
                    [ textarea
                        [ id (PostEditor.getTextareaId editor)
                        , class "w-full h-12 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                        , placeholder "Compose a new post..."
                        , onInput NewPostBodyChanged
                        , onKeydown preventDefault
                            [ ( [ Keys.Meta ], enter, \event -> NewPostSubmit )
                            ]
                        , readonly (PostEditor.isSubmitting editor)
                        , value (PostEditor.getBody editor)
                        , tabindex 1
                        ]
                        []
                    , PostEditor.filesView editor
                    , div [ class "flex items-baseline justify-end" ]
                        [ button
                            [ class "btn btn-blue btn-md flex-no-shrink"
                            , onClick NewPostSubmit
                            , disabled (isUnsubmittable editor)
                            , tabindex 3
                            ]
                            [ text "Send" ]
                        ]
                    ]
                ]
            ]
        ]


controlsView : Model -> Html Msg
controlsView model =
    div [ class "mb-1 flex flex-grow justify-end" ]
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


desktopPostsView : Globals -> Model -> Data -> Html Msg
desktopPostsView globals model data =
    let
        spaceUsers =
            Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo

        groups =
            Repo.getGroups (Space.groupIds data.space) globals.repo
    in
    if Connection.isEmptyAndExpanded model.postComps then
        div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
            [ text "You're all caught up!" ]

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
            div [ class "absolute mt-6 w-2 h-2 rounded-full pin-t pin-b pin-l bg-orange" ] []
        , component
            |> Component.Post.view config
            |> Html.map (PostComponentMsg component.id)
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
            , title = "Feed"
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
            , div [ class "px-4" ] [ mobilePostsView globals model data ]
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


filterTab : Device -> String -> Route.Posts.State -> Params -> Params -> Html Msg
filterTab device label state linkParams currentParams =
    let
        isCurrent =
            Route.Posts.getState currentParams == state
    in
    a
        [ Route.href (Route.Posts linkParams)
        , classList
            [ ( "block text-sm mr-4 py-3 border-b-4 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            , ( "text-center min-w-100px", device == Device.Mobile || device == Device.Desktop )
            ]
        ]
        [ text label ]


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


isUnsubmittable : PostEditor -> Bool
isUnsubmittable editor =
    PostEditor.isUnsubmittable editor || not (String.contains "#" (PostEditor.getBody editor))
