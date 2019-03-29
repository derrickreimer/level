module Page.Posts exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Browser.Navigation as Nav
import Connection
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
import PostView exposing (PostView)
import PushStatus exposing (PushStatus)
import Query.Posts as Posts
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
    , postViews : PostSet
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
    }


type Recipient
    = Nobody
    | Direct
    | Channel


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map2 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)



-- PAGE PROPERTIES


title : Repo -> Model -> String
title repo model =
    oneOf "Home"
        [ recipientsTitle repo model
        , sentTitle repo model
        ]


recipientsTitle : Repo -> Model -> Maybe String
recipientsTitle repo model =
    let
        maybeRecipients =
            model.params
                |> Route.Posts.getRecipients
                |> Maybe.map (\handles -> Repo.getSpaceUsersByHandle model.spaceId handles repo)
    in
    case maybeRecipients of
        Just recipients ->
            if List.map SpaceUser.id recipients == [ model.viewerId ] then
                Just "Private Notes"

            else
                recipients
                    |> List.filter (\su -> SpaceUser.id su /= model.viewerId)
                    |> List.map SpaceUser.displayName
                    |> String.join ", "
                    |> Just

        Nothing ->
            Nothing


sentTitle : Repo -> Model -> Maybe String
sentTitle repo model =
    case resolveData repo model of
        Just data ->
            if Route.Posts.getAuthor model.params == Just (SpaceUser.handle data.viewer) then
                Just "Sent"

            else
                Nothing

        Nothing ->
            Nothing


oneOf : a -> List (Maybe a) -> a
oneOf default maybes =
    case maybes of
        (Just hd) :: tl ->
            hd

        Nothing :: tl ->
            oneOf default tl

        [] ->
            default



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( ( Model, Cmd Msg ), Globals )
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
            Task.succeed (scaffold globals params viewer space)

        _ ->
            Task.fail PageError.NotFound


queryKey : Params -> String
queryKey params =
    Route.toString (Route.Posts params)


scaffold : Globals -> Params -> SpaceUser -> Space -> ( ( Model, Cmd Msg ), Globals )
scaffold globals params viewer space =
    let
        cachedPosts =
            if Repo.hasQuery (queryKey params) globals.repo then
                globals.repo
                    |> Repo.getAllPosts
                    |> filterPosts globals.repo (Space.id space) params
                    |> List.sortWith Post.desc
                    |> List.take 20

            else
                []

        ( postSet, postViewCmds ) =
            if List.isEmpty cachedPosts then
                ( PostSet.empty, [] )

            else
                PostSet.loadCached globals cachedPosts PostSet.empty

        cmds =
            postViewCmds
                |> List.map (\( id, viewCmd ) -> Cmd.map (PostViewMsg id) viewCmd)
                |> Cmd.batch

        model =
            Model
                params
                (SpaceUser.id viewer)
                (Space.id space)
                postSet
                (FieldEditor.init "search-editor" "")
                (PostEditor.init "post-composer")
                False
                False
                False
    in
    ( ( model, cmds ), globals )


setup : Globals -> Model -> Cmd Msg
setup globals model =
    let
        pageCmd =
            PostEditor.fetchLocal model.postComposer

        postsCmd =
            globals.session
                |> Posts.request model.params 20 Nothing
                |> Task.attempt (PostsFetched (queryKey model.params) 20)
    in
    Cmd.batch
        [ pageCmd
        , postsCmd
        , Scroll.toDocumentTop NoOp
        ]


teardown : Globals -> Model -> Cmd Msg
teardown globals model =
    Cmd.none


filterPosts : Repo -> Id -> Params -> List Post -> List Post
filterPosts repo spaceId params posts =
    let
        subscribedGroupIds =
            repo
                |> Repo.getGroupsBySpaceId spaceId
                |> List.filter Group.withSubscribed
                |> List.map Group.id

        authorFilter =
            params
                |> Route.Posts.getAuthor
                |> Maybe.andThen (\handle -> Repo.getActorByHandle spaceId handle repo)

        recipientFilter =
            params
                |> Route.Posts.getRecipients
                |> Maybe.map (\handles -> Repo.getSpaceUsersByHandle spaceId handles repo)
                |> Maybe.map (List.map SpaceUser.id)
    in
    posts
        |> List.filter (Post.withSpace spaceId)
        |> List.filter (Post.withInboxState (Route.Posts.getInboxState params))
        |> List.filter (Post.withFollowing subscribedGroupIds)
        |> List.filter (Post.withAuthor authorFilter)
        |> List.filter (Post.withRecipients recipientFilter)


isMemberPost : Repo -> Model -> Post -> Bool
isMemberPost repo model post =
    not (List.isEmpty (filterPosts repo model.spaceId model.params [ post ]))



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | ToggleNotifications
    | InternalLinkClicked String
    | LoadMoreClicked
    | PostsFetched String Int (Result Session.Error ( Session, Posts.Response ))
    | PostViewMsg String PostView.Msg
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
    | FlushQueueClicked
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

        ToggleNotifications ->
            ( ( model, Cmd.none ), { globals | showNotifications = not globals.showNotifications } )

        InternalLinkClicked pathname ->
            ( ( model, Nav.pushUrl globals.navKey pathname ), globals )

        LoadMoreClicked ->
            let
                newPostViews =
                    model.postViews
                        |> PostSet.setLoadingMore

                cmd =
                    case PostSet.lastPostedAt model.postViews of
                        Just lastPostedAt ->
                            globals.session
                                |> Posts.request model.params 20 (Just lastPostedAt)
                                |> Task.attempt (PostsFetched (queryKey model.params) 20)

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postViews = newPostViews }, cmd ), globals )

        PostsFetched key limit (Ok ( newSession, resp )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.union resp.repo
                        |> Repo.addQuery (queryKey model.params)

                newGlobals =
                    { globals | session = newSession, repo = newRepo }
            in
            if queryKey model.params == key then
                let
                    posts =
                        resp.resolvedPosts
                            |> Connection.toList
                            |> List.map .post

                    ( newModel, setupCmds ) =
                        List.foldr (addPost newGlobals) ( model, Cmd.none ) posts

                    newPostComps =
                        newModel.postViews
                            |> PostSet.setLoaded
                            |> PostSet.sortByPostedAt
                            |> PostSet.setHasMore (Connection.length resp.resolvedPosts >= limit)
                in
                ( ( { newModel | postViews = newPostComps }, setupCmds ), newGlobals )

            else
                ( ( model, Cmd.none ), newGlobals )

        PostsFetched _ _ (Err Session.Expired) ->
            redirectToLogin globals model

        PostsFetched _ _ _ ->
            ( ( model, Cmd.none ), globals )

        PostViewMsg postId postViewMsg ->
            case PostSet.get postId model.postViews of
                Just postView ->
                    let
                        ( ( newPostComp, cmd ), newGlobals ) =
                            PostView.update postViewMsg globals postView
                    in
                    ( ( { model | postViews = PostSet.update newPostComp model.postViews }
                      , Cmd.map (PostViewMsg postId) cmd
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
                        (Just <| FieldEditor.getValue newSearchEditor)

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
            let
                recipientIds =
                    model.params
                        |> Route.Posts.getRecipients
                        |> Maybe.map (\handles -> Repo.getSpaceUsersByHandle model.spaceId handles globals.repo)
                        |> Maybe.map (List.filter (\su -> SpaceUser.id su /= model.viewerId))
                        |> Maybe.map (List.map SpaceUser.id)
                        |> Maybe.withDefault []
            in
            if PostEditor.isSubmittable model.postComposer then
                let
                    variables =
                        CreatePost.variables
                            model.spaceId
                            Nothing
                            recipientIds
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

                ( newPostViews, postViewCmd ) =
                    if isMemberPost globals.repo model resolvedPost.post then
                        PostSet.add newGlobals resolvedPost.post model.postViews

                    else
                        ( model.postViews, Cmd.none )
            in
            ( ( { model | postComposer = newPostComposer, postViews = newPostViews }
              , Cmd.batch
                    [ postComposerCmd
                    , Cmd.map (PostViewMsg (Post.id resolvedPost.post)) postViewCmd
                    ]
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
                newPostViews =
                    PostSet.select postId model.postViews

                cmd =
                    case PostSet.selected newPostViews of
                        Just postView ->
                            postView
                                |> PostView.recordView globals
                                |> Cmd.map (PostViewMsg postId)

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postViews = newPostViews }, cmd ), globals )

        PushSubscribeClicked ->
            ( ( model, ServiceWorker.pushSubscribe ), globals )

        FlushQueueClicked ->
            let
                ( newPostViews, cmd ) =
                    model.postViews
                        |> PostSet.flushQueue globals
                        |> PostSet.mapCommands PostViewMsg
            in
            ( ( { model | postViews = newPostViews }
              , Cmd.batch [ cmd, Scroll.toDocumentTop NoOp ]
              )
            , globals
            )

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
    case PostSet.get (Post.id post) model.postViews of
        Just postView ->
            let
                newPostViews =
                    PostSet.remove (Post.id post) model.postViews

                teardownCmd =
                    Cmd.map (PostViewMsg postView.id)
                        (PostView.teardown globals postView)

                newCmd =
                    Cmd.batch [ cmd, teardownCmd ]
            in
            ( { model | postViews = newPostViews }, newCmd )

        Nothing ->
            ( model, cmd )


enqueuePost : Repo -> Post -> Model -> Model
enqueuePost repo post model =
    if isMemberPost repo model post then
        let
            newPostViews =
                PostSet.enqueue (Post.id post) model.postViews
        in
        { model | postViews = newPostViews }

    else
        model


addPost : Globals -> Post -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
addPost globals post ( model, cmd ) =
    if isMemberPost globals.repo model post then
        let
            ( newPostComps, newCmd ) =
                PostSet.add globals post model.postViews
        in
        ( { model | postViews = newPostComps }
        , Cmd.batch [ cmd, Cmd.map (PostViewMsg (Post.id post)) newCmd ]
        )

    else
        ( model, cmd )



-- EVENTS


consumeEvent : Globals -> Event -> Model -> ( Model, Cmd Msg )
consumeEvent globals event model =
    case event of
        Event.PostCreated resolvedPost ->
            ( enqueuePost globals.repo resolvedPost.post model, Cmd.none )

        Event.ReplyCreated reply ->
            let
                postId =
                    Reply.postId reply
            in
            case PostSet.get postId model.postViews of
                Just postView ->
                    let
                        ( newPostView, cmd ) =
                            PostView.refreshFromCache globals postView
                    in
                    ( { model | postViews = PostSet.update newPostView model.postViews }
                    , Cmd.map (PostViewMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        Event.ReplyDeleted reply ->
            let
                postId =
                    Reply.postId reply
            in
            case PostSet.get postId model.postViews of
                Just postView ->
                    let
                        ( newPostView, cmd ) =
                            PostView.refreshFromCache globals postView
                    in
                    ( { model | postViews = PostSet.update newPostView model.postViews }
                    , Cmd.map (PostViewMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        Event.PostsMarkedAsUnread resolvedPosts ->
            let
                posts =
                    List.map .post resolvedPosts

                newModel =
                    List.foldr (enqueuePost globals.repo) model posts
            in
            if Route.Posts.getInboxState model.params == InboxStateFilter.Dismissed then
                List.foldr (removePost globals) ( newModel, Cmd.none ) posts

            else
                ( newModel, Cmd.none )

        Event.PostsMarkedAsRead resolvedPosts ->
            let
                posts =
                    List.map .post resolvedPosts

                newModel =
                    List.foldr (enqueuePost globals.repo) model posts
            in
            if Route.Posts.getInboxState model.params == InboxStateFilter.Dismissed then
                List.foldr (removePost globals) ( newModel, Cmd.none ) posts

            else
                ( newModel, Cmd.none )

        Event.PostsDismissed resolvedPosts ->
            let
                posts =
                    List.map .post resolvedPosts

                newModel =
                    List.foldr (enqueuePost globals.repo) model posts
            in
            if Route.Posts.getInboxState model.params == InboxStateFilter.Undismissed then
                List.foldr (removePost globals) ( newModel, Cmd.none ) posts

            else
                ( newModel, Cmd.none )

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
                newPostViews =
                    PostSet.selectPrev model.postViews

                cmd =
                    case PostSet.selected newPostViews of
                        Just currentPost ->
                            Cmd.batch
                                [ Scroll.toAnchor Scroll.Document (PostView.postNodeId currentPost) 85
                                , currentPost
                                    |> PostView.recordView globals
                                    |> Cmd.map (PostViewMsg currentPost.id)
                                ]

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postViews = newPostViews }, cmd ), globals )

        ( "j", [] ) ->
            let
                newPostViews =
                    PostSet.selectNext model.postViews

                cmd =
                    case PostSet.selected newPostViews of
                        Just currentPost ->
                            Cmd.batch
                                [ Scroll.toAnchor Scroll.Document (PostView.postNodeId currentPost) 85
                                , currentPost
                                    |> PostView.recordView globals
                                    |> Cmd.map (PostViewMsg currentPost.id)
                                ]

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | postViews = newPostViews }, cmd ), globals )

        ( "e", [] ) ->
            case PostSet.selected model.postViews of
                Just currentPostView ->
                    let
                        newRepo =
                            case Repo.getPost currentPostView.id globals.repo of
                                Just post ->
                                    globals.repo
                                        |> Repo.setPost (Post.setInboxState Post.Dismissed post)

                                Nothing ->
                                    globals.repo

                        cmd =
                            globals.session
                                |> DismissPosts.request model.spaceId [ currentPostView.id ]
                                |> Task.attempt PostsDismissed
                    in
                    ( ( model, cmd ), { globals | repo = newRepo } )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "e", [ Meta ] ) ->
            case PostSet.selected model.postViews of
                Just currentPostView ->
                    let
                        newRepo =
                            case Repo.getPost currentPostView.id globals.repo of
                                Just post ->
                                    globals.repo
                                        |> Repo.setPost (Post.setInboxState Post.Read post)

                                Nothing ->
                                    globals.repo

                        cmd =
                            globals.session
                                |> MarkAsRead.request model.spaceId [ currentPostView.id ]
                                |> Task.attempt PostsMarkedAsRead
                    in
                    ( ( model, cmd ), { globals | repo = newRepo } )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "y", [] ) ->
            case PostSet.selected model.postViews of
                Just currentPostView ->
                    let
                        cmd =
                            globals.session
                                |> ClosePost.request model.spaceId currentPostView.id
                                |> Task.attempt PostClosed
                    in
                    ( ( model, cmd ), globals )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "r", [] ) ->
            case PostSet.selected model.postViews of
                Just currentPostView ->
                    let
                        ( ( newCurrentPost, cmd ), newGlobals ) =
                            PostView.expandReplyComposer globals currentPostView

                        newPostComps =
                            PostSet.update newCurrentPost model.postViews
                    in
                    ( ( { model | postViews = newPostComps }
                      , Cmd.map (PostViewMsg currentPostView.id) cmd
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
    Sub.none



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
            , onPageClicked = NoOp
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 max-w-lg leading-normal" ]
            [ div [ class "scrolled-top-no-border sticky pin-t trans-border-b-grey py-2 bg-white z-40" ]
                [ div [ class "flex items-center" ]
                    [ h2 [ class "flex-no-shrink" ]
                        [ span [ class "font-bold text-2xl" ] [ text <| title globals.repo model ]
                        ]
                    , controlsView model
                    ]
                ]
            , desktopPostComposerView globals model data
            , div [ class "sticky mb-4 pt-1 px-3 bg-white z-30", style "top" "52px" ]
                [ div [ class "flex items-baseline trans-border-b-grey" ]
                    [ filterTab Device.Desktop "Inbox" (undismissedParams model.params) model.params
                    , filterTab Device.Desktop "Everything" (feedParams model.params) model.params
                    ]
                , desktopFlushQueueButton model
                ]
            , PushStatus.bannerView globals.pushStatus PushSubscribeClicked
            , desktopPostsView globals model data
            , viewIf (PostSet.isLoaded model.postViews && PostSet.hasMore model.postViews) <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , onClick LoadMoreClicked
                        ]
                        [ text "Load more..." ]
                    ]
            , viewIf (PostSet.isLoadingMore model.postViews) <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , disabled True
                        ]
                        [ text "Loading..." ]
                    ]
            ]
        ]


desktopFlushQueueButton : Model -> Html Msg
desktopFlushQueueButton model =
    let
        depth =
            PostSet.queueDepth model.postViews
    in
    viewIf (depth > 0) <|
        div
            [ class "absolute"
            , style "left" "50%"
            , style "top" "65px"
            , style "transform" "translateX(-50%)"
            ]
            [ button [ class "btn btn-blue btn-sm shadow", onClick FlushQueueClicked ]
                [ text <| "Show " ++ String.fromInt depth ++ " new post(s)" ]
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

        maybeRecipients =
            model.params
                |> Route.Posts.getRecipients
                |> Maybe.map (\handles -> Repo.getSpaceUsersByHandle model.spaceId handles globals.repo)

        placeholderText =
            case maybeRecipients of
                Just recipients ->
                    if List.map SpaceUser.id recipients == [ model.viewerId ] then
                        "Write a note to yourself..."

                    else
                        recipients
                            |> List.filter (\su -> SpaceUser.id su /= model.viewerId)
                            |> List.map SpaceUser.firstName
                            |> String.join ", "
                            |> String.append "Write to "
                            |> (\text -> String.append text "...")

                Nothing ->
                    "Tag a channel or @mention someone..."

        buttonText =
            case maybeRecipients of
                Just recipients ->
                    if List.map SpaceUser.id recipients == [ model.viewerId ] then
                        "Save Private Note"

                    else
                        "Send Direct Message"

                Nothing ->
                    if PostEditor.getBody editor == "" then
                        "Send"

                    else
                        case determineRecipient (PostEditor.getBody editor) of
                            Nobody ->
                                "Save Private Note"

                            Direct ->
                                "Send Direct Message"

                            Channel ->
                                "Send to Channel"
    in
    PostEditor.wrapper config
        [ label [ class "composer" ]
            [ div [ class "flex" ]
                [ div [ class "flex-no-shrink mt-2 mr-3 z-10" ] [ SpaceUser.avatar Avatar.Medium data.viewer ]
                , div [ class "flex-grow -ml-6 pl-6 pr-3 py-3 bg-grey-light w-full rounded-xl" ]
                    [ textarea
                        [ id (PostEditor.getTextareaId editor)
                        , class "w-full h-8 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                        , placeholder placeholderText
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
    case ( PostSet.isScaffolded model.postViews, PostSet.isEmpty model.postViews ) of
        ( True, False ) ->
            div [] (PostSet.mapList (desktopPostView globals spaceUsers groups model data) model.postViews)

        ( True, True ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "You're all caught up!" ]

        ( False, _ ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "Loading..." ]


desktopPostView : Globals -> List SpaceUser -> List Group -> Model -> Data -> PostView -> Html Msg
desktopPostView globals spaceUsers groups model data postView =
    let
        config =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = globals.now
            , spaceUsers = spaceUsers
            , groups = groups
            , showRecipients = showRecipients model.params
            , isSelected = PostSet.selected model.postViews == Just postView
            }

        isSelected =
            PostSet.selected model.postViews == Just postView
    in
    div
        [ classList
            [ ( "relative p-3", True )
            ]
        , onClick (PostSelected postView.id)
        ]
        [ postView
            |> PostView.view config
            |> Html.map (PostViewMsg postView.id)
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = title globals.repo model
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
            , rightControl =
                Layout.SpaceMobile.Custom <|
                    a
                        [ class "flex items-center justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
                        , rel "tooltip"
                        , Html.Attributes.title "Search"
                        , Route.href (Route.Search <| Route.Search.init (Route.Posts.getSpaceSlug model.params) Nothing)
                        ]
                        [ Icons.search ]
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "mx-auto leading-normal" ]
            [ div [ class "flex justify-center items-baseline mb-3 px-3 pt-2 border-b" ]
                [ filterTab Device.Mobile "Inbox" (undismissedParams model.params) model.params
                , filterTab Device.Mobile "Everything" (feedParams model.params) model.params
                ]
            , PushStatus.bannerView globals.pushStatus PushSubscribeClicked
            , mobileFlushQueueButton model
            , div [ class "p-3 pt-0" ] [ mobilePostsView globals model data ]
            , viewIf (PostSet.isLoaded model.postViews && PostSet.hasMore model.postViews) <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , onClick LoadMoreClicked
                        ]
                        [ text "Load more..." ]
                    ]
            , viewIf (PostSet.isLoadingMore model.postViews) <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , disabled True
                        ]
                        [ text "Loading..." ]
                    ]
            ]
        ]


mobileFlushQueueButton : Model -> Html Msg
mobileFlushQueueButton model =
    let
        depth =
            PostSet.queueDepth model.postViews
    in
    viewIf (depth > 0) <|
        div
            [ class "py-3 text-center"
            ]
            [ button [ class "btn btn-blue btn-sm shadow", onClick FlushQueueClicked ]
                [ text <| "Show " ++ String.fromInt depth ++ " new post(s)" ]
            ]


mobilePostsView : Globals -> Model -> Data -> Html Msg
mobilePostsView globals model data =
    let
        spaceUsers =
            Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo

        groups =
            Repo.getGroups (Space.groupIds data.space) globals.repo
    in
    case ( PostSet.isScaffolded model.postViews, PostSet.isEmpty model.postViews ) of
        ( True, False ) ->
            div [] (PostSet.mapList (mobilePostView globals spaceUsers groups model data) model.postViews)

        ( True, True ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "You're all caught up!" ]

        ( False, _ ) ->
            div [ class "pt-16 pb-16 font-headline text-center text-lg text-dusty-blue-dark" ]
                [ text "Loading..." ]


mobilePostView : Globals -> List SpaceUser -> List Group -> Model -> Data -> PostView -> Html Msg
mobilePostView globals spaceUsers groups model data postView =
    let
        config =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = globals.now
            , spaceUsers = spaceUsers
            , groups = groups
            , showRecipients = showRecipients model.params
            , isSelected = False
            }
    in
    div [ class "py-4" ]
        [ postView
            |> PostView.view config
            |> Html.map (PostViewMsg postView.id)
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
            [ ( "flex-1 -mb-px block text-md py-3 px-4 border-b-3 border-transparent no-underline font-bold text-center", True )
            , ( "text-dusty-blue-dark", not isCurrent )
            , ( "border-blue text-blue", isCurrent )
            ]
        ]
        [ text label ]


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


showRecipients : Params -> Bool
showRecipients params =
    List.isEmpty (Route.Posts.getRecipients params |> Maybe.withDefault [])


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
        |> Route.Posts.setState PostStateFilter.All


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
