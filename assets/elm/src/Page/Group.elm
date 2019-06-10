module Page.Group exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, receivePresence, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Browser.Navigation as Nav
import Connection exposing (Connection)
import Device exposing (Device)
import Element
import Event exposing (Event)
import FieldEditor exposing (FieldEditor)
import File exposing (File)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership, GroupMembershipState(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import InboxStateFilter
import Json.Decode as Decode
import KeyboardShortcuts exposing (Modifier(..))
import Layout.SpaceDesktop
import Layout.SpaceMobile
import Lazy exposing (Lazy(..))
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BookmarkGroup as BookmarkGroup
import Mutation.CloseGroup as CloseGroup
import Mutation.ClosePost as ClosePost
import Mutation.CreatePost as CreatePost
import Mutation.DismissPosts as DismissPosts
import Mutation.MarkAsRead as MarkAsRead
import Mutation.ReopenGroup as ReopenGroup
import Mutation.SubscribeToGroup as SubscribeToGroup
import Mutation.UnbookmarkGroup as UnbookmarkGroup
import Mutation.UnsubscribeFromGroup as UnsubscribeFromGroup
import Mutation.UpdateGroup as UpdateGroup
import Mutation.WatchGroup as WatchGroup
import PageError exposing (PageError)
import Pagination
import Post exposing (Post)
import PostEditor exposing (PostEditor)
import PostSet exposing (PostSet)
import PostStateFilter
import PostView exposing (PostView)
import Presence
import PushStatus
import Query.FeaturedMemberships as FeaturedMemberships
import Query.GroupPosts as GroupPosts
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Route exposing (Route)
import Route.Group exposing (Params(..))
import Route.GroupSettings
import Route.NewGroupPost
import Route.Search
import Route.SpaceUser
import Scroll
import ServiceWorker
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Subscription.GroupSubscription as GroupSubscription
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import TimeWithZone exposing (TimeWithZone)
import ValidationError exposing (ValidationError)
import Vendor.Keys as Keys exposing (enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (selectValue, setFocus, smartFormatTime, viewIf, viewUnless)
import View.SearchBox



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , groupId : Id
    , featuredMemberIds : Lazy (List Id)
    , postViews : PostSet
    , nameEditor : FieldEditor String
    , postComposer : PostEditor
    , searchEditor : FieldEditor String
    , isChangingSubscription : Bool
    , isSubscriptionDropdownOpen : Bool
    , isSubscribersDropdownOpen : Bool

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , group : Group
    , featuredMembers : Lazy (List SpaceUser)
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Repo.getGroup model.groupId repo)
        (Just <| Lazy.map (\ids -> Repo.getSpaceUsers ids repo) model.featuredMemberIds)



-- PAGE PROPERTIES


title : Repo -> Model -> String
title repo model =
    case Repo.getGroup model.groupId repo of
        Just group ->
            "#" ++ Group.name group

        Nothing ->
            "Group"



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( ( Model, Cmd Msg ), Globals )
init params globals =
    let
        maybeUserId =
            Session.getUserId globals.session

        maybeSpace =
            Repo.getSpaceBySlug (Route.Group.getSpaceSlug params) globals.repo

        maybeViewer =
            case ( maybeSpace, maybeUserId ) of
                ( Just space, Just userId ) ->
                    Repo.getSpaceUserByUserId (Space.id space) userId globals.repo

                _ ->
                    Nothing

        maybeGroup =
            case maybeSpace of
                Just space ->
                    Repo.getGroupByName (Space.id space) (Route.Group.getGroupName params) globals.repo

                Nothing ->
                    Nothing
    in
    case ( maybeViewer, maybeSpace, maybeGroup ) of
        ( Just viewer, Just space, Just group ) ->
            Task.succeed (scaffold globals params viewer space group)

        _ ->
            Task.fail PageError.NotFound


queryKey : Params -> String
queryKey params =
    Route.toString (Route.Group params)


scaffold : Globals -> Params -> SpaceUser -> Space -> Group -> ( ( Model, Cmd Msg ), Globals )
scaffold globals params viewer space group =
    let
        cachedPosts =
            if Repo.hasQuery (queryKey params) globals.repo then
                globals.repo
                    |> Repo.getPostsByGroup (Group.id group) Nothing
                    |> filterPosts (Space.id space) (Group.id group) params
                    |> List.sortWith Post.desc
                    |> List.take 1000

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
                (Group.id group)
                NotLoaded
                postSet
                (FieldEditor.init "name-editor" "")
                (PostEditor.init ("post-composer-" ++ Group.id group))
                (FieldEditor.init "search-editor" "")
                False
                False
                False
                False
                False
    in
    ( ( model, cmds ), globals )


setup : Globals -> Model -> Cmd Msg
setup globals model =
    let
        pageCmd =
            Cmd.batch
                [ setupSockets model.groupId
                , PostEditor.fetchLocal model.postComposer
                ]

        postsCmd =
            globals.session
                |> GroupPosts.request model.params 1000 Nothing
                |> Task.attempt (PostsFetched (queryKey model.params) 1000)

        featuredMembersCmd =
            globals.session
                |> FeaturedMemberships.request model.groupId
                |> Task.attempt FeaturedMembershipsRefreshed
    in
    Cmd.batch
        [ pageCmd
        , postsCmd
        , featuredMembersCmd
        , Scroll.toDocumentTop NoOp
        ]


teardown : Globals -> Model -> Cmd Msg
teardown globals model =
    let
        pageCmd =
            teardownSockets model.groupId

        postsCmd =
            model.postViews
                |> PostSet.mapList (\postView -> Cmd.map (PostViewMsg postView.id) (PostView.teardown globals postView))
                |> Cmd.batch
    in
    Cmd.batch [ pageCmd, postsCmd ]


setupSockets : Id -> Cmd Msg
setupSockets groupId =
    GroupSubscription.subscribe groupId


teardownSockets : Id -> Cmd Msg
teardownSockets groupId =
    GroupSubscription.unsubscribe groupId


filterPosts : Id -> Id -> Params -> List Post -> List Post
filterPosts spaceId groupId params posts =
    posts
        |> List.filter (Post.withSpace spaceId)
        |> List.filter (Post.withGroup groupId)
        |> List.filter (Post.withInboxState (Route.Group.getInboxState params))
        |> List.filter Post.notDeleted


isMemberPost : Model -> Post -> Bool
isMemberPost model post =
    not (List.isEmpty (filterPosts model.spaceId model.groupId model.params [ post ]))



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | ToggleNotifications
    | InternalLinkClicked String
    | PageClicked
    | LoadMoreClicked
    | PostsFetched String Int (Result Session.Error ( Session, GroupPosts.Response ))
    | PostEditorEventReceived Decode.Value
    | NewPostBodyChanged String
    | NewPostFileAdded File
    | NewPostFileUploadProgress Id Int
    | NewPostFileUploaded Id Id String
    | NewPostFileUploadError Id
    | ToggleUrgent
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, CreatePost.Response ))
    | SubscriptionDropdownToggled
    | SubscribersDropdownToggled
    | SubscribeClicked
    | Subscribed (Result Session.Error ( Session, SubscribeToGroup.Response ))
    | UnsubscribeClicked
    | Unsubscribed (Result Session.Error ( Session, UnsubscribeFromGroup.Response ))
    | WatchClicked
    | Watched (Result Session.Error ( Session, WatchGroup.Response ))
    | NameClicked
    | NameEditorChanged String
    | NameEditorDismissed
    | NameEditorSubmit
    | NameEditorSubmitted (Result Session.Error ( Session, UpdateGroup.Response ))
    | FeaturedMembershipsRefreshed (Result Session.Error ( Session, FeaturedMemberships.Response ))
    | PostViewMsg String PostView.Msg
    | Bookmark
    | Bookmarked (Result Session.Error ( Session, BookmarkGroup.Response ))
    | Unbookmark
    | Unbookmarked (Result Session.Error ( Session, UnbookmarkGroup.Response ))
    | PrivacyToggle Bool
    | PrivacyToggled (Result Session.Error ( Session, UpdateGroup.Response ))
    | ExpandSearchEditor
    | CollapseSearchEditor
    | SearchEditorChanged String
    | SearchSubmitted
    | CloseClicked
    | Closed (Result Session.Error ( Session, CloseGroup.Response ))
    | ReopenClicked
    | Reopened (Result Session.Error ( Session, ReopenGroup.Response ))
    | PostsDismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | PostsMarkedAsRead (Result Session.Error ( Session, MarkAsRead.Response ))
    | PostClosed (Result Session.Error ( Session, ClosePost.Response ))
    | PostSelected Id
    | FocusOnComposer
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

        PageClicked ->
            ( ( { model
                    | isSubscriptionDropdownOpen = False
                    , isSubscribersDropdownOpen = False
                }
              , Cmd.none
              )
            , globals
            )

        LoadMoreClicked ->
            let
                newPostViews =
                    model.postViews
                        |> PostSet.setLoadingMore

                cmd =
                    case PostSet.lastPostedAt model.postViews of
                        Just lastPostedAt ->
                            globals.session
                                |> GroupPosts.request model.params 20 (Just lastPostedAt)
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
                            |> PostSet.setHasMore (List.length posts >= limit)
                in
                ( ( { newModel | postViews = newPostComps }, setupCmds ), newGlobals )

            else
                ( ( model, Cmd.none ), newGlobals )

        PostsFetched _ _ (Err Session.Expired) ->
            redirectToLogin globals model

        PostsFetched _ _ _ ->
            ( ( model, Cmd.none ), globals )

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

        NewPostFileUploadError clientId ->
            noCmd globals { model | postComposer = PostEditor.setFileState clientId File.UploadError model.postComposer }

        ToggleUrgent ->
            ( ( { model | postComposer = PostEditor.toggleIsUrgent model.postComposer }, Cmd.none ), globals )

        NewPostSubmit ->
            if PostEditor.isSubmittable model.postComposer then
                let
                    variables =
                        CreatePost.variables
                            model.spaceId
                            (Just model.groupId)
                            []
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
                    if isMemberPost model resolvedPost.post then
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

        SubscriptionDropdownToggled ->
            ( ( { model
                    | isSubscriptionDropdownOpen = not model.isSubscriptionDropdownOpen
                    , isSubscribersDropdownOpen = False
                }
              , Cmd.none
              )
            , globals
            )

        SubscribersDropdownToggled ->
            ( ( { model
                    | isSubscribersDropdownOpen = not model.isSubscribersDropdownOpen
                    , isSubscriptionDropdownOpen = False
                }
              , Cmd.none
              )
            , globals
            )

        SubscribeClicked ->
            let
                cmd =
                    globals.session
                        |> SubscribeToGroup.request model.spaceId model.groupId
                        |> Task.attempt Subscribed
            in
            ( ( { model | isChangingSubscription = True, isSubscriptionDropdownOpen = False }, cmd ), globals )

        Subscribed (Ok ( newSession, SubscribeToGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( { model | isChangingSubscription = False }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        Subscribed (Ok ( newSession, SubscribeToGroup.Invalid _ )) ->
            noCmd globals model

        Subscribed (Err Session.Expired) ->
            redirectToLogin globals model

        Subscribed (Err _) ->
            noCmd globals model

        UnsubscribeClicked ->
            let
                cmd =
                    globals.session
                        |> UnsubscribeFromGroup.request model.spaceId model.groupId
                        |> Task.attempt Unsubscribed
            in
            ( ( { model | isChangingSubscription = True, isSubscriptionDropdownOpen = False }, cmd ), globals )

        Unsubscribed (Ok ( newSession, UnsubscribeFromGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( { model | isChangingSubscription = False }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        Unsubscribed (Ok ( newSession, UnsubscribeFromGroup.Invalid _ )) ->
            noCmd globals model

        Unsubscribed (Err Session.Expired) ->
            redirectToLogin globals model

        Unsubscribed (Err _) ->
            noCmd globals model

        WatchClicked ->
            let
                cmd =
                    globals.session
                        |> WatchGroup.request model.spaceId model.groupId
                        |> Task.attempt Watched
            in
            ( ( { model | isChangingSubscription = True, isSubscriptionDropdownOpen = False }, cmd ), globals )

        Watched (Ok ( newSession, WatchGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( { model | isChangingSubscription = False }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        Watched (Ok ( newSession, WatchGroup.Invalid _ )) ->
            noCmd globals model

        Watched (Err Session.Expired) ->
            redirectToLogin globals model

        Watched (Err _) ->
            noCmd globals model

        NameClicked ->
            case resolveData globals.repo model of
                Just data ->
                    let
                        nodeId =
                            FieldEditor.getNodeId model.nameEditor

                        newNameEditor =
                            model.nameEditor
                                |> FieldEditor.expand
                                |> FieldEditor.setValue (Group.name data.group)
                                |> FieldEditor.setErrors []

                        cmd =
                            Cmd.batch
                                [ setFocus nodeId NoOp
                                , selectValue nodeId
                                ]
                    in
                    ( ( { model | nameEditor = newNameEditor }, cmd ), globals )

                Nothing ->
                    noCmd globals model

        NameEditorChanged val ->
            let
                newValue =
                    val
                        |> String.toLower
                        |> String.replace " " "-"

                newNameEditor =
                    model.nameEditor
                        |> FieldEditor.setValue newValue
            in
            noCmd globals { model | nameEditor = newNameEditor }

        NameEditorDismissed ->
            let
                newNameEditor =
                    model.nameEditor
                        |> FieldEditor.collapse
            in
            noCmd globals { model | nameEditor = newNameEditor }

        NameEditorSubmit ->
            let
                newNameEditor =
                    model.nameEditor
                        |> FieldEditor.setIsSubmitting True

                variables =
                    UpdateGroup.variables model.spaceId model.groupId (Just (FieldEditor.getValue newNameEditor)) Nothing

                cmd =
                    globals.session
                        |> UpdateGroup.request variables
                        |> Task.attempt NameEditorSubmitted
            in
            ( ( { model | nameEditor = newNameEditor }, cmd ), globals )

        NameEditorSubmitted (Ok ( newSession, UpdateGroup.Success newGroup )) ->
            let
                newNameEditor =
                    model.nameEditor
                        |> FieldEditor.collapse
                        |> FieldEditor.setIsSubmitting False

                newModel =
                    { model | nameEditor = newNameEditor }

                repo =
                    globals.repo
                        |> Repo.setGroup newGroup
            in
            noCmd { globals | session = newSession, repo = repo } newModel

        NameEditorSubmitted (Ok ( newSession, UpdateGroup.Invalid errors )) ->
            let
                newNameEditor =
                    model.nameEditor
                        |> FieldEditor.setErrors errors
                        |> FieldEditor.setIsSubmitting False
            in
            ( ( { model | nameEditor = newNameEditor }
              , selectValue (FieldEditor.getNodeId newNameEditor)
              )
            , { globals | session = newSession }
            )

        NameEditorSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NameEditorSubmitted (Err _) ->
            let
                newNameEditor =
                    model.nameEditor
                        |> FieldEditor.setIsSubmitting False
                        |> FieldEditor.setErrors [ ValidationError "name" "Hmm, something went wrong." ]
            in
            ( ( { model | nameEditor = newNameEditor }, Cmd.none )
            , globals
            )

        FeaturedMembershipsRefreshed (Ok ( newSession, resp )) ->
            let
                newRepo =
                    Repo.union resp.repo globals.repo
            in
            ( ( { model | featuredMemberIds = Loaded resp.spaceUserIds }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        FeaturedMembershipsRefreshed (Err Session.Expired) ->
            redirectToLogin globals model

        FeaturedMembershipsRefreshed (Err _) ->
            noCmd globals model

        PostViewMsg postId postViewMsg ->
            case PostSet.get postId model.postViews of
                Just postView ->
                    let
                        ( ( newPostView, cmd ), newGlobals ) =
                            PostView.update postViewMsg globals postView
                    in
                    ( ( { model | postViews = PostSet.update newPostView model.postViews }
                      , Cmd.map (PostViewMsg postId) cmd
                      )
                    , newGlobals
                    )

                Nothing ->
                    noCmd globals model

        Bookmark ->
            let
                cmd =
                    globals.session
                        |> BookmarkGroup.request model.spaceId model.groupId
                        |> Task.attempt Bookmarked
            in
            ( ( model, cmd ), globals )

        Bookmarked (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        Bookmarked (Err Session.Expired) ->
            redirectToLogin globals model

        Bookmarked (Err _) ->
            noCmd globals model

        Unbookmark ->
            let
                cmd =
                    globals.session
                        |> UnbookmarkGroup.request model.spaceId model.groupId
                        |> Task.attempt Unbookmarked
            in
            ( ( model, cmd ), globals )

        Unbookmarked (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        Unbookmarked (Err Session.Expired) ->
            redirectToLogin globals model

        Unbookmarked (Err _) ->
            noCmd globals model

        PrivacyToggle isPrivate ->
            let
                variables =
                    UpdateGroup.variables model.spaceId model.groupId Nothing (Just isPrivate)

                cmd =
                    globals.session
                        |> UpdateGroup.request variables
                        |> Task.attempt PrivacyToggled
            in
            ( ( model, cmd ), globals )

        PrivacyToggled (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        PrivacyToggled (Err Session.Expired) ->
            redirectToLogin globals model

        PrivacyToggled (Err _) ->
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
                        (Route.Group.getSpaceSlug model.params)
                        (Just <| FieldEditor.getValue newSearchEditor)

                cmd =
                    Route.pushUrl globals.navKey (Route.Search searchParams)
            in
            ( ( { model | searchEditor = newSearchEditor }, cmd ), globals )

        CloseClicked ->
            let
                cmd =
                    globals.session
                        |> CloseGroup.request model.spaceId model.groupId
                        |> Task.attempt Closed
            in
            ( ( model, cmd ), globals )

        Closed (Ok ( newSession, CloseGroup.Success newGroup )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup newGroup
            in
            noCmd { globals | session = newSession, repo = newRepo } model

        Closed (Err Session.Expired) ->
            redirectToLogin globals model

        Closed (Err _) ->
            noCmd globals model

        ReopenClicked ->
            let
                cmd =
                    globals.session
                        |> ReopenGroup.request model.spaceId model.groupId
                        |> Task.attempt Reopened
            in
            ( ( model, cmd ), globals )

        Reopened (Ok ( newSession, ReopenGroup.Success newGroup )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup newGroup
            in
            noCmd { globals | session = newSession, repo = newRepo } model

        Reopened (Err Session.Expired) ->
            redirectToLogin globals model

        Reopened (Err _) ->
            noCmd globals model

        PostsDismissed _ ->
            noCmd { globals | flash = Flash.set Flash.Notice "Dismissed from inbox" 3000 globals.flash } model

        PostsMarkedAsRead _ ->
            noCmd { globals | flash = Flash.set Flash.Notice "Moved to inbox" 3000 globals.flash } model

        PostClosed _ ->
            noCmd { globals | flash = Flash.set Flash.Notice "Marked as resolved" 3000 globals.flash } model

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

        FocusOnComposer ->
            ( ( model, setFocus (PostEditor.getTextareaId model.postComposer) NoOp ), globals )

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


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )


expandSearchEditor : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
expandSearchEditor globals model =
    ( ( { model | searchEditor = FieldEditor.expand model.searchEditor }
      , setFocus (FieldEditor.getNodeId model.searchEditor) NoOp
      )
    , globals
    )


enqueuePost : Post -> Model -> Model
enqueuePost post model =
    if isMemberPost model post then
        let
            newPostComps =
                PostSet.enqueue (Post.id post) model.postViews
        in
        { model | postViews = newPostComps }

    else
        model


addPost : Globals -> Post -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
addPost globals post ( model, cmd ) =
    if isMemberPost model post then
        let
            ( newPostComps, newCmd ) =
                PostSet.add globals post model.postViews
        in
        ( { model | postViews = newPostComps }
        , Cmd.batch [ cmd, Cmd.map (PostViewMsg (Post.id post)) newCmd ]
        )

    else
        ( model, cmd )


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



-- EVENTS


consumeEvent : Globals -> Event -> Model -> ( Model, Cmd Msg )
consumeEvent globals event model =
    case event of
        Event.SubscribedToGroup group ->
            if Group.id group == model.groupId then
                ( model
                , FeaturedMemberships.request model.groupId globals.session
                    |> Task.attempt FeaturedMembershipsRefreshed
                )

            else
                ( model, Cmd.none )

        Event.UnsubscribedFromGroup group ->
            if Group.id group == model.groupId then
                ( model
                , FeaturedMemberships.request model.groupId globals.session
                    |> Task.attempt FeaturedMembershipsRefreshed
                )

            else
                ( model, Cmd.none )

        Event.PostCreated resolvedPost ->
            ( enqueuePost resolvedPost.post model, Cmd.none )

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
                    List.foldr enqueuePost model posts
            in
            if Route.Group.getInboxState model.params == InboxStateFilter.Dismissed then
                List.foldr (removePost globals) ( newModel, Cmd.none ) posts

            else
                ( newModel, Cmd.none )

        Event.PostsMarkedAsRead resolvedPosts ->
            let
                posts =
                    List.map .post resolvedPosts

                newModel =
                    List.foldr enqueuePost model posts
            in
            if Route.Group.getInboxState model.params == InboxStateFilter.Dismissed then
                List.foldr (removePost globals) ( newModel, Cmd.none ) posts

            else
                ( newModel, Cmd.none )

        Event.PostsDismissed resolvedPosts ->
            let
                posts =
                    List.map .post resolvedPosts

                newModel =
                    List.foldr enqueuePost model posts
            in
            if Route.Group.getInboxState model.params == InboxStateFilter.Undismissed then
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
                                [ Scroll.toAnchor Scroll.Document (PostView.postNodeId currentPost) 125
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
                                [ Scroll.toAnchor Scroll.Document (PostView.postNodeId currentPost) 125
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
                        ( ( newCurrentPost, compCmd ), newGlobals ) =
                            PostView.expandReplyComposer globals currentPostView

                        newPostComps =
                            PostSet.update newCurrentPost model.postViews
                    in
                    ( ( { model | postViews = newPostComps }
                      , Cmd.map (PostViewMsg currentPostView.id) compCmd
                      )
                    , globals
                    )

                Nothing ->
                    ( ( model, Cmd.none ), globals )

        ( "c", [] ) ->
            ( ( model, setFocus (PostEditor.getTextareaId model.postComposer) NoOp ), globals )

        ( "Escape", [] ) ->
            ( ( { model | isSubscriptionDropdownOpen = False }, Cmd.none ), globals )

        _ ->
            ( ( model, Cmd.none ), globals )


receivePresence : Presence.Event -> Globals -> Model -> ( Model, Cmd Msg )
receivePresence event globals model =
    let
        viewsAndCmds =
            PostSet.mapList (PostView.receivePresence event globals) model.postViews

        reducer ( postView, cmd ) ( postSet, cmdBatch ) =
            ( PostSet.update postView postSet
            , Cmd.batch [ Cmd.map (PostViewMsg postView.id) cmd, cmdBatch ]
            )

        ( newPostViews, cmds ) =
            List.foldr reducer ( model.postViews, Cmd.none ) viewsAndCmds

        newModel =
            { model | postViews = newPostViews }
    in
    ( newModel, cmds )



-- SUBSCRIPTION


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ PostEditor.receive PostEditorEventReceived
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
    case ( globals.device, Route.Group.isPlainText model.params ) of
        ( Device.Desktop, False ) ->
            resolvedDesktopView globals model data

        ( Device.Mobile, False ) ->
            resolvedMobileView globals model data

        ( _, True ) ->
            plainTextView globals model data



-- PLAIN TEXT


plainTextView : Globals -> Model -> Data -> Html Msg
plainTextView globals model data =
    let
        spaceUsers =
            Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo

        groups =
            Repo.getGroups (Space.groupIds data.space) globals.repo
    in
    div [ class "p-8" ]
        (PostSet.mapList (plainTextPostView globals spaceUsers groups model data) model.postViews)


plainTextPostView : Globals -> List SpaceUser -> List Group -> Model -> Data -> PostView -> Html Msg
plainTextPostView globals spaceUsers groups model data postView =
    let
        config =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = globals.now
            , spaceUsers = spaceUsers
            , groups = groups
            , showRecipients = False
            , isSelected = PostSet.selected model.postViews == Just postView
            }
    in
    postView
        |> PostView.plainTextView config
        |> Html.map (PostViewMsg postView.id)



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
            , onPageClicked = PageClicked
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 max-w-lg leading-normal" ]
            [ div [ class "scrolled-top-no-border sticky pin-t trans-border-b-grey py-2 bg-white z-40" ]
                [ div [ class "flex items-center" ]
                    [ nameView data.group model.nameEditor
                    , viewIf (Group.isPrivate data.group) <|
                        div
                            [ class "tooltip tooltip-bottom ml-2"
                            , attribute "data-tooltip" "This channel is private"
                            ]
                            [ Icons.lockLarge ]
                    , nameErrors model.nameEditor
                    , controlsView model data
                    ]
                ]
            , viewIf (Group.state data.group == Group.Open) <|
                desktopPostComposerView globals model data
            , viewIf (Group.state data.group == Group.Closed) <|
                p [ class "flex items-center px-4 py-3 mb-4 bg-red-lightest border-b-2 border-red text-red font-bold" ]
                    [ div [ class "flex-grow" ] [ text "This channel is closed." ]
                    , div [ class "flex-no-shrink" ]
                        [ button [ class "btn btn-red btn-sm", onClick ReopenClicked ] [ text "Reopen the channel" ]
                        ]
                    ]
            , div [ class "sticky mb-4 pt-1 px-3 bg-white z-30", style "top" "52px" ]
                [ div [ class "flex items-baseline trans-border-b-grey" ]
                    [ filterTab Device.Desktop "Inbox" (undismissedParams model.params) model.params
                    , filterTab Device.Desktop "Everything" (feedParams model.params) model.params
                    ]
                , desktopFlushQueueButton model
                ]
            , viewUnless (Space.isDemo data.space) <|
                PushStatus.bannerView globals.pushStatus PushSubscribeClicked
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


nameView : Group -> FieldEditor String -> Html Msg
nameView group editor =
    case ( FieldEditor.isExpanded editor, FieldEditor.isSubmitting editor ) of
        ( False, _ ) ->
            h2 [ class "flex-no-shrink" ]
                [ span [ class "text-2xl font-normal text-dusty-blue-dark" ] [ text "#" ]
                , span
                    [ onClick NameClicked
                    , class "font-bold text-2xl cursor-pointer"
                    ]
                    [ text (Group.name group) ]
                ]

        ( True, False ) ->
            h2 [ class "flex flex-no-shrink" ]
                [ div [ class "mr-1 text-2xl font-normal text-dusty-blue-dark" ] [ text "#" ]
                , input
                    [ type_ "text"
                    , id (FieldEditor.getNodeId editor)
                    , classList
                        [ ( "px-2 bg-grey-light font-bold text-2xl text-dusty-blue-darkest rounded no-outline js-stretchy", True )
                        , ( "shake", not <| List.isEmpty (FieldEditor.getErrors editor) )
                        ]
                    , value (FieldEditor.getValue editor)
                    , onInput NameEditorChanged
                    , onKeydown preventDefault
                        [ ( [], enter, \event -> NameEditorSubmit )
                        , ( [], esc, \event -> NameEditorDismissed )
                        ]
                    , onBlur NameEditorDismissed
                    ]
                    []
                ]

        ( _, True ) ->
            h2 [ class "flex-no-shrink" ]
                [ input
                    [ type_ "text"
                    , class "-ml-2 px-2 bg-grey-light font-bold text-2xl text-dusty-blue-darkest rounded no-outline"
                    , value (FieldEditor.getValue editor)
                    , disabled True
                    ]
                    []
                ]


nameErrors : FieldEditor String -> Html Msg
nameErrors editor =
    case ( FieldEditor.isExpanded editor, List.head (FieldEditor.getErrors editor) ) of
        ( True, Just error ) ->
            span [ class "ml-2 flex-grow text-sm text-red font-bold" ] [ text error.message ]

        ( _, _ ) ->
            text ""


controlsView : Model -> Data -> Html Msg
controlsView model data =
    let
        settingsParams =
            Route.GroupSettings.init
                (Route.Group.getSpaceSlug model.params)
                (Route.Group.getGroupName model.params)
                Route.GroupSettings.General
    in
    div [ class "flex flex-grow justify-end" ]
        [ subscriptionDropdown model data

        -- , div [ class "ml-2" ]
        --     [ View.SearchBox.view
        --         { editor = model.searchEditor
        --         , changeMsg = SearchEditorChanged
        --         , expandMsg = ExpandSearchEditor
        --         , collapseMsg = CollapseSearchEditor
        --         , submitMsg = SearchSubmitted
        --         }
        --     ]
        , subscribersDropdown model data
        , a
            [ Route.href (Route.GroupSettings settingsParams)
            , class "tooltip tooltip-bottom ml-2 flex items-center justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
            , attribute "data-tooltip" "Settings"
            ]
            [ Icons.settings ]
        ]


subscribersDropdown : Model -> Data -> Html Msg
subscribersDropdown model data =
    Element.dropdown NoOp
        [ button
            [ classList
                [ ( "ml-2 flex items-center justify-center w-9 h-9 rounded-full", True )
                , ( "bg-transparent hover:bg-grey transition-bg", not model.isSubscriptionDropdownOpen )
                , ( "bg-grey", model.isSubscribersDropdownOpen )
                ]
            , onClick SubscribersDropdownToggled
            ]
            [ Icons.people ]
        , div
            [ classList
                [ ( "absolute bg-white mt-1 py-1 pin-r w-56 max-h-screen shadow-dropdown rounded-lg z-50 overflow-y-auto", True )
                , ( "hidden", not model.isSubscribersDropdownOpen )
                ]
            , style "max-height" "300px"
            ]
            [ memberListView data.space data.featuredMembers
            ]
        ]


subscriptionDropdown : Model -> Data -> Html Msg
subscriptionDropdown model data =
    let
        currentState =
            Group.membershipState data.group

        buttonText =
            case currentState of
                GroupMembership.NotSubscribed ->
                    "Not Subscribed"

                GroupMembership.Subscribed ->
                    "Subscribed"

                GroupMembership.Watching ->
                    "Watching"

        currentItem headline description =
            div [ class "flex w-full p-3 border-b text-left bg-grey-light last-child:border-none" ]
                [ div [ class "flex-no-shrink w-9 mt-1 pl-1" ] [ Icons.check ]
                , div [ class "flex-grow" ]
                    [ h3 [ class "pb-1 font-sans text-base text-dusty-blue-darker" ] [ text headline ]
                    , p [ class "text-dusty-blue-dark text-sm leading-normal" ] [ text description ]
                    ]
                ]

        transitionButton clickMsg headline description =
            button [ class "flex w-full p-3 border-b text-left hover:bg-grey-lighter last-child:border-none", onClick clickMsg ]
                [ div [ class "flex-no-shrink w-9" ] []
                , div [ class "flex-grow" ]
                    [ h3 [ class "pb-1 font-sans text-base text-dusty-blue-darker" ] [ text headline ]
                    , p [ class "text-dusty-blue-dark text-sm leading-normal" ] [ text description ]
                    ]
                ]
    in
    Element.dropdown NoOp
        [ button
            [ classList
                [ ( "flex items-center justify-center px-4 h-9 rounded-full no-outline", True )
                , ( "text-dusty-blue hover:text-dusty-blue-dark text-md font-bold", True )
                , ( "bg-transparent hover:bg-grey transition-bg", not model.isSubscriptionDropdownOpen )
                , ( "bg-grey", model.isSubscriptionDropdownOpen )
                ]
            , onClick SubscriptionDropdownToggled
            , disabled model.isChangingSubscription
            ]
            [ text buttonText
            , viewIf (not model.isSubscriptionDropdownOpen) <| div [ class "ml-2" ] [ Icons.chevronDown ]
            , viewIf model.isSubscriptionDropdownOpen <| div [ class "ml-2" ] [ Icons.chevronUp ]
            ]
        , div
            [ classList
                [ ( "absolute bg-white mt-1 pin-r w-80 shadow-dropdown rounded-lg z-50 overflow-hidden", True )
                , ( "hidden", not model.isSubscriptionDropdownOpen )
                ]
            ]
            [ viewIf (currentState == GroupMembership.NotSubscribed) <|
                currentItem "Not Subscribed" "Posts do not appear in your Home timelime."
            , viewIf (currentState /= GroupMembership.NotSubscribed) <|
                transitionButton UnsubscribeClicked "Unsubscribe" "Posts will not appear in your Home timelime."
            , viewIf (currentState == GroupMembership.Subscribed) <|
                currentItem "Subscribed" "Posts appear in your Home timelime, but not in your Inbox unless you are mentioned."
            , viewIf (currentState /= GroupMembership.Subscribed) <|
                transitionButton SubscribeClicked "Subscribe" "Posts will appear in your Home timelime, but not in your Inbox unless you are mentioned."
            , viewIf (currentState == GroupMembership.Watching) <|
                currentItem "Watching" "Posts appear in your Home timelime and in your Inbox (regardless of whether you are mentioned)."
            , viewIf (currentState /= GroupMembership.Watching) <|
                transitionButton WatchClicked "Watch" "Posts will appear in your Home timelime and in your Inbox (regardless of whether you are mentioned)."
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
    in
    PostEditor.wrapper config
        [ label [ class "composer pl-3" ]
            [ div [ class "flex" ]
                [ div [ class "flex-no-shrink mt-2 mr-3 z-10" ] [ SpaceUser.avatar Avatar.Medium data.viewer ]
                , div [ class "flex-grow -ml-6 pl-6 pr-3 py-3 bg-grey-light w-full rounded-xl" ]
                    [ textarea
                        [ id (PostEditor.getTextareaId editor)
                        , class "w-full h-8 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal fs-block"
                        , placeholder <| "Write to #" ++ Group.name data.group ++ "..."
                        , onInput NewPostBodyChanged
                        , onKeydown preventDefault [ ( [ Keys.Meta ], enter, \event -> NewPostSubmit ) ]
                        , readonly (PostEditor.isSubmitting editor)
                        , value (PostEditor.getBody editor)
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
                            , disabled (PostEditor.isUnsubmittable editor)
                            ]
                            [ text "Send" ]
                        ]
                    ]
                ]
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
            , showRecipients = False
            , isSelected = PostSet.selected model.postViews == Just postView
            }
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
            , title = "#" ++ Group.name data.group
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "flex justify-center items-baseline mb-3 px-3 pt-2 border-b" ]
            [ filterTab Device.Mobile "Inbox" (undismissedParams model.params) model.params
            , filterTab Device.Mobile "Everything" (feedParams model.params) model.params
            ]
        , viewIf (Group.state data.group == Group.Closed) <|
            p [ class "flex items-center px-4 py-3 mb-4 bg-red-lightest border-b-2 border-red text-red font-bold" ]
                [ div [ class "flex-grow" ] [ text "This group is closed." ]
                , div [ class "flex-no-shrink" ]
                    [ button [ class "btn btn-blue btn-sm", onClick ReopenClicked ] [ text "Reopen this group" ]
                    ]
                ]
        , PushStatus.bannerView globals.pushStatus PushSubscribeClicked
        , mobileFlushQueueButton model
        , div [ class "p-3 pt-0" ]
            [ mobilePostsView globals model data
            , viewIf (PostSet.isScaffolded model.postViews && PostSet.hasMore model.postViews) <|
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
        , a
            [ Route.href <| Route.NewGroupPost (Route.NewGroupPost.init (Route.Group.getSpaceSlug model.params) (Route.Group.getGroupName model.params))
            , class "flex items-center justify-center fixed w-16 h-16 bg-turquoise rounded-full shadow"
            , style "bottom" "25px"
            , style "right" "25px"
            ]
            [ Icons.commentWhite ]
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
            , showRecipients = False
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
            Route.Group.getState currentParams
                == Route.Group.getState linkParams
                && Route.Group.getInboxState currentParams
                == Route.Group.getInboxState linkParams
    in
    a
        [ Route.href (Route.Group linkParams)
        , classList
            [ ( "flex-1 -mb-px block text-md py-3 px-4 border-b-3 border-transparent no-underline font-bold text-center", True )
            , ( "text-dusty-blue-dark", not isCurrent )
            , ( "border-blue text-blue", isCurrent )
            ]
        ]
        [ text label ]


bookmarkButtonView : Bool -> Html Msg
bookmarkButtonView isBookmarked =
    if isBookmarked == True then
        button
            [ class "ml-3 tooltip tooltip-bottom"
            , onClick Unbookmark
            , attribute "data-tooltip" "Unbookmark"
            ]
            [ Icons.bookmark Icons.On ]

    else
        button
            [ class "ml-3 tooltip tooltip-bottom"
            , onClick Bookmark
            , attribute "data-tooltip" "Bookmark"
            ]
            [ Icons.bookmark Icons.Off ]


memberListView : Space -> Lazy (List SpaceUser) -> Html Msg
memberListView space featuredMembers =
    case featuredMembers of
        Loaded members ->
            if List.isEmpty members then
                div [ class "px-3 py-2 text-base text-dusty-blue-dark" ] [ text "Nobody is subscribed." ]

            else
                div [] <| List.map (memberItemView space) members

        NotLoaded ->
            div [ class "px-3 py-2 text-base text-dusty-blue-dark" ] [ text "Loading..." ]


memberItemView : Space -> SpaceUser -> Html Msg
memberItemView space user =
    a
        [ Route.href <| Route.SpaceUser (Route.SpaceUser.init (Space.slug space) (SpaceUser.handle user))
        , class "flex items-center px-2 py-1 no-underline text-dusty-blue-darker hover:bg-grey-light"
        ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Small user ]
        , div [ class "flex-grow text-base truncate" ] [ text <| SpaceUser.displayName user ]
        ]



-- INTERNAL


undismissedParams : Params -> Params
undismissedParams params =
    params
        |> Route.Group.clearFilters
        |> Route.Group.setState PostStateFilter.All
        |> Route.Group.setInboxState InboxStateFilter.Undismissed


feedParams : Params -> Params
feedParams params =
    params
        |> Route.Group.clearFilters
        |> Route.Group.setState PostStateFilter.All
