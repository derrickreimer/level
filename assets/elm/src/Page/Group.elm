module Page.Group exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Event exposing (Event)
import FieldEditor exposing (FieldEditor)
import File exposing (File)
import Globals exposing (Globals)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership, GroupMembershipState(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import KeyboardShortcuts
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BookmarkGroup as BookmarkGroup
import Mutation.CreatePost as CreatePost
import Mutation.SubscribeToGroup as SubscribeToGroup
import Mutation.UnbookmarkGroup as UnbookmarkGroup
import Mutation.UnsubscribeFromGroup as UnsubscribeFromGroup
import Mutation.UpdateGroup as UpdateGroup
import Pagination
import Post exposing (Post)
import PostEditor exposing (PostEditor)
import Query.FeaturedMemberships as FeaturedMemberships
import Query.GroupInit as GroupInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group exposing (Params(..))
import Route.GroupPermissions
import Route.Search
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Subscription.GroupSubscription as GroupSubscription
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import ValidationError exposing (ValidationError)
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (selectValue, setFocus, smartFormatTime, viewIf, viewUnless)
import View.SearchBox
import View.SpaceLayout



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , groupId : Id
    , featuredMemberIds : List Id
    , postComps : Connection Component.Post.Model
    , now : ( Zone, Posix )
    , nameEditor : FieldEditor String
    , postComposer : PostEditor
    , searchEditor : FieldEditor String
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    , featuredMembers : List SpaceUser
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map5 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)
        (Repo.getGroup model.groupId repo)
        (Just <| Repo.getSpaceUsers model.featuredMemberIds repo)



-- PAGE PROPERTIES


title : Repo -> Model -> String
title repo model =
    case Repo.getGroup model.groupId repo of
        Just group ->
            Group.name group

        Nothing ->
            "Group"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> GroupInit.request params 10
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( ( Session, GroupInit.Response ), ( Zone, Posix ) ) -> ( Globals, Model )
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
                resp.groupId
                resp.featuredMemberIds
                postComps
                now
                (FieldEditor.init "name-editor" "")
                (PostEditor.init "post-composer")
                (FieldEditor.init "search-editor" "")

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


buildPostComponent : Params -> ( Id, Connection Id ) -> Component.Post.Model
buildPostComponent params ( postId, replyIds ) =
    Component.Post.init Component.Post.Feed False (Route.Group.getSpaceSlug params) postId replyIds


setup : Model -> Cmd Msg
setup model =
    let
        pageCmd =
            Cmd.batch
                [ setFocus "post-composer" NoOp
                , setupSockets model.groupId
                ]

        postsCmd =
            Connection.toList model.postComps
                |> List.map (\post -> Cmd.map (PostComponentMsg post.id) (Component.Post.setup post))
                |> Cmd.batch
    in
    Cmd.batch
        [ pageCmd
        , postsCmd
        , Scroll.toDocumentTop NoOp
        ]


teardown : Model -> Cmd Msg
teardown model =
    let
        pageCmd =
            teardownSockets model.groupId

        postsCmd =
            Connection.toList model.postComps
                |> List.map (\post -> Cmd.map (PostComponentMsg post.id) (Component.Post.teardown post))
                |> Cmd.batch
    in
    Cmd.batch [ pageCmd, postsCmd ]


setupSockets : Id -> Cmd Msg
setupSockets groupId =
    GroupSubscription.subscribe groupId


teardownSockets : Id -> Cmd Msg
teardownSockets groupId =
    GroupSubscription.unsubscribe groupId



-- UPDATE


type Msg
    = NoOp
    | Tick Posix
    | SetCurrentTime Posix Zone
    | NewPostBodyChanged String
    | NewPostFileAdded File
    | NewPostFileUploadProgress Id Int
    | NewPostFileUploaded Id Id String
    | NewPostFileUploadError Id
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, CreatePost.Response ))
    | SubscribeClicked
    | Subscribed (Result Session.Error ( Session, SubscribeToGroup.Response ))
    | UnsubscribeClicked
    | Unsubscribed (Result Session.Error ( Session, UnsubscribeFromGroup.Response ))
    | NameClicked
    | NameEditorChanged String
    | NameEditorDismissed
    | NameEditorSubmit
    | NameEditorSubmitted (Result Session.Error ( Session, UpdateGroup.Response ))
    | FeaturedMembershipsRefreshed (Result Session.Error ( Session, FeaturedMemberships.Response ))
    | PostComponentMsg String Component.Post.Msg
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


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), globals )

        SetCurrentTime posix zone ->
            noCmd globals { model | now = ( zone, posix ) }

        NewPostBodyChanged value ->
            noCmd globals { model | postComposer = PostEditor.setBody value model.postComposer }

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

        NewPostSubmit ->
            if PostEditor.isSubmittable model.postComposer then
                let
                    cmd =
                        globals.session
                            |> CreatePost.request model.spaceId model.groupId (PostEditor.getBody model.postComposer) (PostEditor.getUploadIds model.postComposer)
                            |> Task.attempt NewPostSubmitted
                in
                ( ( { model | postComposer = PostEditor.setToSubmitting model.postComposer }, cmd ), globals )

            else
                noCmd globals model

        NewPostSubmitted (Ok ( newSession, response )) ->
            let
                newPostComposer =
                    model.postComposer
                        |> PostEditor.reset
            in
            ( ( { model | postComposer = newPostComposer }
              , Cmd.none
              )
            , { globals | session = newSession }
            )

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewPostSubmitted (Err _) ->
            { model | postComposer = PostEditor.setNotSubmitting model.postComposer }
                |> noCmd globals

        SubscribeClicked ->
            let
                cmd =
                    globals.session
                        |> SubscribeToGroup.request model.spaceId model.groupId
                        |> Task.attempt Subscribed
            in
            ( ( model, cmd ), globals )

        Subscribed (Ok ( newSession, SubscribeToGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( model, Cmd.none ), { globals | session = newSession, repo = newRepo } )

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
            ( ( model, cmd ), globals )

        Unsubscribed (Ok ( newSession, UnsubscribeFromGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( model, Cmd.none ), { globals | session = newSession, repo = newRepo } )

        Unsubscribed (Ok ( newSession, UnsubscribeFromGroup.Invalid _ )) ->
            noCmd globals model

        Unsubscribed (Err Session.Expired) ->
            redirectToLogin globals model

        Unsubscribed (Err _) ->
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
                newNameEditor =
                    model.nameEditor
                        |> FieldEditor.setValue val
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

                cmd =
                    globals.session
                        |> UpdateGroup.request model.spaceId model.groupId (Just (FieldEditor.getValue newNameEditor)) Nothing
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
            ( ( { model | featuredMemberIds = resp.spaceUserIds }, Cmd.none )
            , { globals | session = newSession, repo = newRepo }
            )

        FeaturedMembershipsRefreshed (Err Session.Expired) ->
            redirectToLogin globals model

        FeaturedMembershipsRefreshed (Err _) ->
            noCmd globals model

        PostComponentMsg postId componentMsg ->
            case Connection.get .id postId model.postComps of
                Just postComp ->
                    let
                        ( ( newPostComp, cmd ), newGlobals ) =
                            Component.Post.update componentMsg model.spaceId globals postComp
                    in
                    ( ( { model | postComps = Connection.update .id newPostComp model.postComps }
                      , Cmd.map (PostComponentMsg postId) cmd
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
                cmd =
                    globals.session
                        |> UpdateGroup.request model.spaceId model.groupId Nothing (Just isPrivate)
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
                        (Route.Group.getSpaceSlug model.params)
                        (FieldEditor.getValue newSearchEditor)

                cmd =
                    Route.pushUrl globals.navKey (Route.Search searchParams)
            in
            ( ( { model | searchEditor = newSearchEditor }, cmd ), globals )


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



-- EVENTS


consumeEvent : Event -> Session -> Model -> ( Model, Cmd Msg )
consumeEvent event session model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.SubscribedToGroup group ->
            if Group.id group == model.groupId then
                ( model
                , FeaturedMemberships.request model.groupId session
                    |> Task.attempt FeaturedMembershipsRefreshed
                )

            else
                ( model, Cmd.none )

        Event.UnsubscribedFromGroup group ->
            if Group.id group == model.groupId then
                ( model
                , FeaturedMemberships.request model.groupId session
                    |> Task.attempt FeaturedMembershipsRefreshed
                )

            else
                ( model, Cmd.none )

        Event.PostCreated ( post, replies ) ->
            let
                postComp =
                    Component.Post.init
                        Component.Post.Feed
                        False
                        (Route.Group.getSpaceSlug model.params)
                        (Post.id post)
                        (Connection.map Reply.id replies)
            in
            if List.member model.groupId (Post.groupIds post) then
                ( { model | postComps = Connection.prepend .id postComp model.postComps }
                , Cmd.map (PostComponentMsg <| Post.id post) (Component.Post.setup postComp)
                )

            else
                ( model, Cmd.none )

        Event.ReplyCreated reply ->
            let
                postId =
                    Reply.postId reply
            in
            case Connection.get .id postId model.postComps of
                Just postComp ->
                    let
                        ( newPostComp, cmd ) =
                            Component.Post.handleReplyCreated reply postComp
                    in
                    ( { model | postComps = Connection.update .id newPostComp model.postComps }
                    , Cmd.map (PostComponentMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTION


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ every 1000 Tick
        , KeyboardShortcuts.subscribe
            [ ( "/", ExpandSearchEditor )
            ]
        ]



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
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ div [ class "scrolled-top-no-border sticky pin-t border-b py-4 bg-white z-40" ]
                [ div [ class "flex items-center" ]
                    [ nameView data.group model.nameEditor
                    , bookmarkButtonView (Group.isBookmarked data.group)
                    , nameErrors model.nameEditor
                    , controlsView model
                    ]
                ]
            , newPostView model.spaceId model.postComposer data.viewer
            , postsView repo data.space data.viewer model.now model.postComps
            , sidebarView model.params data.group data.featuredMembers
            ]
        ]


nameView : Group -> FieldEditor String -> Html Msg
nameView group editor =
    case ( FieldEditor.isExpanded editor, FieldEditor.isSubmitting editor ) of
        ( False, _ ) ->
            h2 [ class "flex-no-shrink" ]
                [ span
                    [ onClick NameClicked
                    , class "font-extrabold text-2xl cursor-pointer"
                    ]
                    [ text (Group.name group) ]
                ]

        ( True, False ) ->
            h2 [ class "flex-no-shrink" ]
                [ input
                    [ type_ "text"
                    , id (FieldEditor.getNodeId editor)
                    , classList
                        [ ( "-ml-2 px-2 bg-grey-light font-extrabold text-2xl text-dusty-blue-darkest rounded no-outline js-stretchy", True )
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
                    , class "-ml-2 px-2 bg-grey-light font-extrabold text-2xl text-dusty-blue-darkest rounded no-outline"
                    , value (FieldEditor.getValue editor)
                    , disabled True
                    ]
                    []
                ]


privacyIcon : Bool -> Html Msg
privacyIcon isPrivate =
    if isPrivate == True then
        span [ class "mx-2" ] [ Icons.lock ]

    else
        span [ class "mx-2" ] [ Icons.unlock ]


nameErrors : FieldEditor String -> Html Msg
nameErrors editor =
    case ( FieldEditor.isExpanded editor, List.head (FieldEditor.getErrors editor) ) of
        ( True, Just error ) ->
            span [ class "ml-2 flex-grow text-sm text-red font-bold" ] [ text error.message ]

        ( _, _ ) ->
            text ""


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


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (\beforeCursor -> Route.Group (Route.Group.setCursors (Just beforeCursor) Nothing params))
        (\afterCursor -> Route.Group (Route.Group.setCursors Nothing (Just afterCursor) params))


bookmarkButtonView : Bool -> Html Msg
bookmarkButtonView isBookmarked =
    if isBookmarked == True then
        button [ class "ml-3", onClick Unbookmark ]
            [ Icons.bookmark Icons.On ]

    else
        button [ class "ml-3", onClick Bookmark ]
            [ Icons.bookmark Icons.Off ]


newPostView : Id -> PostEditor -> SpaceUser -> Html Msg
newPostView spaceId editor currentUser =
    let
        config =
            { spaceId = spaceId
            , onFileAdded = NewPostFileAdded
            , onFileUploadProgress = NewPostFileUploadProgress
            , onFileUploaded = NewPostFileUploaded
            , onFileUploadError = NewPostFileUploadError
            }
    in
    PostEditor.wrapper config
        [ label [ class "composer mb-4" ]
            [ div [ class "flex" ]
                [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Medium currentUser ]
                , div [ class "flex-grow pl-2 pt-2" ]
                    [ textarea
                        [ id (PostEditor.getId editor)
                        , class "w-full h-10 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                        , placeholder "Compose a new post..."
                        , onInput NewPostBodyChanged
                        , onKeydown preventDefault [ ( [ Meta ], enter, \event -> NewPostSubmit ) ]
                        , readonly (PostEditor.isSubmitting editor)
                        , value (PostEditor.getBody editor)
                        ]
                        []
                    , PostEditor.filesView editor
                    , div [ class "flex items-baseline justify-end" ]
                        [ div [ class "mr-3 text-sm text-dusty-blue" ]
                            [ text "Press ⌘↩ or" ]
                        , button
                            [ class "btn btn-blue btn-md"
                            , onClick NewPostSubmit
                            , disabled (PostEditor.isUnsubmittable editor)
                            ]
                            [ text "Post message" ]
                        ]
                    ]
                ]
            ]
        ]


postsView : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> Connection Component.Post.Model -> Html Msg
postsView repo space currentUser now connection =
    if Connection.isEmptyAndExpanded connection then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "Be the first one to post here!" ]

    else
        div [] <|
            Connection.mapList (postView repo space currentUser now) connection


postView : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> Component.Post.Model -> Html Msg
postView repo space currentUser now component =
    div [ class "p-4" ]
        [ Component.Post.view repo space currentUser now component
            |> Html.map (PostComponentMsg component.id)
        ]


sidebarView : Params -> Group -> List SpaceUser -> Html Msg
sidebarView params group featuredMembers =
    let
        permissionsParams =
            Route.GroupPermissions.init
                (Route.Group.getSpaceSlug params)
                (Route.Group.getGroupId params)
    in
    View.SpaceLayout.rightSidebar
        [ h3 [ class "flex items-center mb-2 text-base font-extrabold" ]
            [ text "Members"

            -- Hide this for now while private groups are disabled
            , viewIf False <|
                privacyIcon (Group.isPrivate group)
            ]
        , memberListView featuredMembers
        , ul [ class "list-reset leading-normal" ]
            [ -- Hide this for now while private groups are disabled
              viewIf False <|
                li []
                    [ a
                        [ Route.href (Route.GroupPermissions permissionsParams)
                        , class "text-md text-dusty-blue no-underline font-bold"
                        ]
                        [ text "Permissions" ]
                    ]
            , li []
                [ subscribeButtonView (Group.membershipState group)
                ]
            ]
        ]


memberListView : List SpaceUser -> Html Msg
memberListView featuredMembers =
    if List.isEmpty featuredMembers then
        div [ class "pb-4 text-sm text-dusty-blue-darker" ] [ text "Nobody has joined yet." ]

    else
        div [ class "pb-4" ] <| List.map memberItemView featuredMembers


memberItemView : SpaceUser -> Html Msg
memberItemView member =
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Tiny member ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| SpaceUser.displayName member ]
        ]


subscribeButtonView : GroupMembershipState -> Html Msg
subscribeButtonView state =
    case state of
        GroupMembership.NotSubscribed ->
            button
                [ class "text-md text-dusty-blue no-underline font-bold"
                , onClick SubscribeClicked
                ]
                [ text "Join this group" ]

        GroupMembership.Subscribed ->
            button
                [ class "text-md text-dusty-blue no-underline font-bold"
                , onClick UnsubscribeClicked
                ]
                [ text "Leave this group" ]
