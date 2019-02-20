module Page.Posts exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
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
import InboxStateFilter exposing (InboxStateFilter)
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
import PageError exposing (PageError)
import Pagination
import Post exposing (Post)
import PostEditor exposing (PostEditor)
import PostSet exposing (PostSet)
import PostStateFilter exposing (PostStateFilter)
import PushStatus exposing (PushStatus)
import Query.PostsInit as PostsInit
import Regex exposing (Regex)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Route exposing (Route)
import Route.Posts exposing (Params(..))
import Route.Search
import Route.SpaceUser
import Route.SpaceUsers
import Scroll
import ServiceWorker
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import TimeWithZone exposing (TimeWithZone)
import Vendor.Keys as Keys exposing (enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, smartFormatTime, viewIf, viewUnless)
import View.SearchBox



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , featuredUserIds : List Id
    , postComps : PostSet
    , now : TimeWithZone
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
    , featuredUsers : List SpaceUser
    }


type Recipient
    = Nobody
    | Direct
    | Channel


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getSpaceUsers model.featuredUserIds repo)



-- PAGE PROPERTIES


title : String
title =
    "Home"



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( Globals, Model )
init params globals =
    let
        maybeUserId =
            Session.getUserId globals.session

        maybeSpace =
            Repo.getSpaceBySlug (Route.Posts.getSpaceSlug params) globals.repo

        maybeViewer =
            case ( maybeSpace, maybeUserId ) of
                ( Just space, Just userId ) ->
                    Repo.getSpaceUserByUserId (Space.id space) userId globals.repo

                _ ->
                    Nothing
    in
    case ( maybeViewer, maybeSpace ) of
        ( Just viewer, Just space ) ->
            TimeWithZone.now
                |> Task.andThen (\now -> Task.succeed ( globals, scaffold params viewer space now ))

        _ ->
            Task.fail PageError.NotFound


scaffold : Params -> SpaceUser -> Space -> TimeWithZone -> Model
scaffold params viewer space now =
    Model
        params
        (SpaceUser.id viewer)
        (Space.id space)
        []
        PostSet.empty
        now
        (FieldEditor.init "search-editor" "")
        (PostEditor.init "post-composer")
        False
        False
        False


setup : Globals -> Model -> Cmd Msg
setup globals model =
    Cmd.batch
        [ Scroll.toDocumentTop NoOp
        ]


teardown : Globals -> Model -> Cmd Msg
teardown globals model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | Tick Posix
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
    | ToggleUrgent
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, CreatePost.Response ))
    | PostSelected Id
    | PushSubscribeClicked
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
            ( ( { model | now = TimeWithZone.setPosix posix model.now }, Cmd.none ), globals )

        PostComponentMsg postId componentMsg ->
            case PostSet.get postId model.postComps of
                Just postComp ->
                    let
                        ( ( newPostComp, cmd ), newGlobals ) =
                            Component.Post.update componentMsg globals postComp
                    in
                    ( ( { model | postComps = PostSet.update newPostComp model.postComps }
                      , Cmd.map (PostComponentMsg postId) cmd
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

        PostsDismissed (Ok ( newSession, DismissPosts.Success posts )) ->
            let
                ( newModel, cmd ) =
                    if Route.Posts.getInboxState model.params == InboxStateFilter.Undismissed then
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

        ToggleUrgent ->
            ( ( { model | postComposer = PostEditor.toggleIsUrgent model.postComposer }, Cmd.none ), globals )

        NewPostSubmit ->
            if PostEditor.isSubmittable model.postComposer then
                let
                    variables =
                        CreatePost.variablesWithoutGroup
                            model.spaceId
                            (PostEditor.getBody model.postComposer)
                            (PostEditor.getUploadIds model.postComposer)
                            (PostEditor.getIsUrgent model.postComposer)

                    cmd =
                        globals.session
                            |> CreatePost.request variables
                            |> Task.attempt NewPostSubmitted
                in
                ( ( { model | postComposer = PostEditor.setToSubmitting model.postComposer }, cmd ), globals )

            else
                noCmd globals model

        NewPostSubmitted (Ok ( newSession, CreatePost.Success resolvedPost )) ->
            let
                newRepo =
                    ResolvedPostWithReplies.addToRepo resolvedPost globals.repo

                newGlobals =
                    { globals | session = newSession, repo = newRepo }

                ( newPostComposer, postComposerCmd ) =
                    model.postComposer
                        |> PostEditor.reset

                ( postId, _ ) =
                    ResolvedPostWithReplies.unresolve resolvedPost

                ( newPostComps, postSetupCmd ) =
                    PostSet.prepend globals resolvedPost model.postComps
            in
            ( ( { model | postComposer = newPostComposer, postComps = newPostComps }
              , Cmd.batch [ postComposerCmd, Cmd.map (PostComponentMsg postId) postSetupCmd ]
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

        PostSelected postId ->
            let
                newPostComps =
                    PostSet.select postId model.postComps
            in
            ( ( { model | postComps = newPostComps }, Cmd.none ), globals )

        PushSubscribeClicked ->
            ( ( model, ServiceWorker.pushSubscribe ), globals )

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


removePost : Globals -> Post -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
removePost globals post ( model, cmd ) =
    case PostSet.get (Post.id post) model.postComps of
        Just postComp ->
            let
                newPostComps =
                    PostSet.remove (Post.id post) model.postComps

                teardownCmd =
                    Cmd.map (PostComponentMsg postComp.id)
                        (Component.Post.teardown globals postComp)

                newCmd =
                    Cmd.batch [ cmd, teardownCmd ]
            in
            ( { model | postComps = newPostComps }, newCmd )

        Nothing ->
            ( model, cmd )


addPost : Globals -> ResolvedPostWithReplies -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
addPost globals resolvedPost ( model, cmd ) =
    if Post.spaceId resolvedPost.post == model.spaceId then
        let
            ( newPostComps, setupCmd ) =
                PostSet.prepend globals resolvedPost model.postComps

            newCmd =
                Cmd.batch
                    [ cmd
                    , Cmd.map (PostComponentMsg (Post.id resolvedPost.post)) setupCmd
                    ]
        in
        ( { model | postComps = newPostComps }, newCmd )

    else
        ( model, cmd )



-- EVENTS


consumeEvent : Globals -> Event -> Model -> ( Model, Cmd Msg )
consumeEvent globals event model =
    case event of
        Event.ReplyCreated reply ->
            let
                postId =
                    Reply.postId reply
            in
            case PostSet.get postId model.postComps of
                Just postComp ->
                    let
                        ( newPostComp, cmd ) =
                            Component.Post.handleReplyCreated reply postComp
                    in
                    ( { model | postComps = PostSet.update newPostComp model.postComps }
                    , Cmd.map (PostComponentMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        Event.PostsMarkedAsUnread resolvedPosts ->
            if Route.Posts.getInboxState model.params == InboxStateFilter.Undismissed then
                List.foldr (addPost globals) ( model, Cmd.none ) resolvedPosts

            else if Route.Posts.getInboxState model.params == InboxStateFilter.Dismissed then
                List.foldr (removePost globals) ( model, Cmd.none ) (List.map .post resolvedPosts)

            else
                ( model, Cmd.none )

        Event.PostsMarkedAsRead resolvedPosts ->
            if Route.Posts.getInboxState model.params == InboxStateFilter.Undismissed then
                List.foldr (addPost globals) ( model, Cmd.none ) resolvedPosts

            else if Route.Posts.getInboxState model.params == InboxStateFilter.Dismissed then
                List.foldr (removePost globals) ( model, Cmd.none ) (List.map .post resolvedPosts)

            else
                ( model, Cmd.none )

        Event.PostsDismissed resolvedPosts ->
            if Route.Posts.getInboxState model.params == InboxStateFilter.Undismissed then
                List.foldr (removePost globals) ( model, Cmd.none ) (List.map .post resolvedPosts)

            else if Route.Posts.getInboxState model.params == InboxStateFilter.Dismissed then
                List.foldr (addPost globals) ( model, Cmd.none ) resolvedPosts

            else
                ( model, Cmd.none )

        Event.PostDeleted post ->
            removePost globals post ( model, Cmd.none )

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
                    PostSet.selectPrev model.postComps

                cmd =
                    case PostSet.selected newPostComps of
                        Just currentPost ->
                            Scroll.toAnchor Scroll.Document (Component.Post.postNodeId currentPost.postId) 85

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postComps = newPostComps }, cmd ), globals )

        ( "j", [] ) ->
            let
                newPostComps =
                    PostSet.selectNext model.postComps

                cmd =
                    case PostSet.selected newPostComps of
                        Just currentPost ->
                            Scroll.toAnchor Scroll.Document (Component.Post.postNodeId currentPost.postId) 85

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postComps = newPostComps }, cmd ), globals )

        ( "e", [] ) ->
            case PostSet.selected model.postComps of
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
            case PostSet.selected model.postComps of
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
            case PostSet.selected model.postComps of
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
            case PostSet.selected model.postComps of
                Just currentPost ->
                    let
                        ( ( newCurrentPost, compCmd ), newGlobals ) =
                            Component.Post.expandReplyComposer globals currentPost

                        newPostComps =
                            PostSet.update newCurrentPost model.postComps
                    in
                    ( ( { model | postComps = newPostComps }
                      , Cmd.map (PostComponentMsg currentPost.id) compCmd
                      )
                    , globals
                    )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "c", [] ) ->
            ( ( model, setFocus (PostEditor.getTextareaId model.postComposer) NoOp ), globals )

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
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 py-4 max-w-lg leading-normal" ]
            [ desktopPostComposerView globals model data
            , div [ class "sticky pin-t mb-4 pt-1 bg-white z-20" ]
                [ div [ class "mx-3 flex items-baseline trans-border-b-grey" ]
                    [ filterTab Device.Desktop "Inbox" (undismissedParams model.params) model.params
                    , filterTab Device.Desktop "Feed" (feedParams model.params) model.params
                    , filterTab Device.Desktop "Resolved" (resolvedParams model.params) model.params
                    ]
                ]
            , PushStatus.bannerView globals.pushStatus PushSubscribeClicked
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

        buttonText =
            if PostEditor.getBody editor == "" then
                "Send"

            else
                case determineRecipient (PostEditor.getBody editor) of
                    Nobody ->
                        "Save Private Note"

                    Direct ->
                        "Send Direct Message "

                    Channel ->
                        "Send to Channel"
    in
    PostEditor.wrapper config
        [ label [ class "composer" ]
            [ div [ class "flex" ]
                [ div [ class "flex-no-shrink mr-3" ] [ SpaceUser.avatar Avatar.Medium data.viewer ]
                , div [ class "flex-grow pt-2" ]
                    [ textarea
                        [ id (PostEditor.getTextareaId editor)
                        , class "w-full h-8 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                        , placeholder "Write something..."
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
                    , div [ class "flex items-center justify-end" ]
                        [ viewUnless (PostEditor.getIsUrgent editor) <|
                            button
                                [ class "tooltip tooltip-bottom mr-2 p-1 rounded-full bg-grey-light hover:bg-grey transition-bg no-outline"
                                , attribute "data-tooltip" "Interrupt all @mentioned people"
                                , onClick ToggleUrgent
                                ]
                                [ Icons.alert Icons.Off ]
                        , viewIf (PostEditor.getIsUrgent editor) <|
                            button
                                [ class "tooltip tooltip-bottom mr-2 p-1 rounded-full bg-grey-light hover:bg-grey transition-bg no-outline"
                                , attribute "data-tooltip" "Don't interrupt anyone"
                                , onClick ToggleUrgent
                                ]
                                [ Icons.alert Icons.On ]
                        , button
                            [ class "btn btn-blue btn-sm"
                            , onClick NewPostSubmit
                            , disabled (isUnsubmittable editor)
                            , tabindex 3
                            ]
                            [ text buttonText ]
                        ]
                    ]
                ]
            ]
        ]


controlsView : Model -> Html Msg
controlsView model =
    div [ class "flex flex-grow justify-end" ]
        [ searchEditorView model.searchEditor
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
    case ( PostSet.isLoaded model.postComps, PostSet.isEmpty model.postComps ) of
        ( True, False ) ->
            div [] (PostSet.mapList (desktopPostView globals spaceUsers groups model data) model.postComps)

        ( True, True ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "You're all caught up!" ]

        ( False, _ ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "Loading..." ]


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
            PostSet.selected model.postComps == Just component
    in
    div
        [ classList
            [ ( "relative mb-3 p-3", True )
            ]
        , onClick (PostSelected component.id)
        ]
        [ viewIf isSelected <|
            div
                [ class "tooltip tooltip-top cursor-default absolute mt-3 w-2 h-2 rounded-full pin-t pin-l bg-turquoise"
                , attribute "data-tooltip" "Currently selected"
                ]
                []
        , component
            |> Component.Post.view config
            |> Html.map (PostComponentMsg component.id)
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = "Home"
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
                [ filterTab Device.Mobile "Inbox" (undismissedParams model.params) model.params
                , filterTab Device.Mobile "Feed" (feedParams model.params) model.params
                , filterTab Device.Mobile "Resolved" (resolvedParams model.params) model.params
                ]
            , PushStatus.bannerView globals.pushStatus PushSubscribeClicked
            , div [ class "p-3 pt-0" ] [ mobilePostsView globals model data ]
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
    case ( PostSet.isLoaded model.postComps, PostSet.isEmpty model.postComps ) of
        ( True, False ) ->
            div [] (PostSet.mapList (mobilePostView globals spaceUsers groups model data) model.postComps)

        ( True, True ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "You're all caught up!" ]

        ( False, _ ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "Loading..." ]


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


filterTab : Device -> String -> Params -> Params -> Html Msg
filterTab device label linkParams currentParams =
    let
        isCurrent =
            Route.Posts.getState currentParams
                == Route.Posts.getState linkParams
                && Route.Posts.getInboxState currentParams
                == Route.Posts.getInboxState linkParams
    in
    a
        [ Route.href (Route.Posts linkParams)
        , classList
            [ ( "flex-1 block text-md py-3 px-4 border-b-3 border-transparent no-underline font-bold text-center", True )
            , ( "text-dusty-blue-dark", not isCurrent )
            , ( "border-blue text-blue", isCurrent )
            ]
        ]
        [ text label ]


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
        [ Route.href <| Route.SpaceUser (Route.SpaceUser.init (Space.slug space) (SpaceUser.handle user))
        , class "flex items-center pr-4 mb-px no-underline text-dusty-blue-darker"
        ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Tiny user ]
        , div [ class "flex-grow text-md truncate" ] [ text <| SpaceUser.displayName user ]
        ]



-- INTERNAL


undismissedParams : Params -> Params
undismissedParams params =
    params
        |> Route.Posts.clearFilters
        |> Route.Posts.setState PostStateFilter.All
        |> Route.Posts.setInboxState InboxStateFilter.Undismissed


dismissedParams : Params -> Params
dismissedParams params =
    params
        |> Route.Posts.clearFilters
        |> Route.Posts.setState PostStateFilter.All
        |> Route.Posts.setInboxState InboxStateFilter.Dismissed


feedParams : Params -> Params
feedParams params =
    params
        |> Route.Posts.clearFilters
        |> Route.Posts.setState PostStateFilter.Open


resolvedParams : Params -> Params
resolvedParams params =
    params
        |> Route.Posts.clearFilters
        |> Route.Posts.setState PostStateFilter.Closed


isUnsubmittable : PostEditor -> Bool
isUnsubmittable editor =
    PostEditor.isUnsubmittable editor


determineRecipient : String -> Recipient
determineRecipient text =
    if Regex.contains hashtagRegex text then
        Channel

    else if Regex.contains mentionRegex text then
        Direct

    else
        Nobody


mentionRegex : Regex
mentionRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromStringWith { caseInsensitive = True, multiline = True }
            "(?:^|\\W)@(\\#?[a-z0-9][a-z0-9-]*)(?!\\/)(?=\\.+[ \\t\\W]|\\.+$|[^0-9a-zA-Z_.]|$)"


hashtagRegex : Regex
hashtagRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromStringWith { caseInsensitive = True, multiline = True }
            "(?:^|\\W)\\#([a-z0-9][a-z0-9-]*)(?!\\/)(?=\\.+[ \\t\\W]|\\.+$|[^0-9a-zA-Z_.]|$)"
