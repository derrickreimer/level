module Page.Group exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Autosize
import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership, GroupMembershipState(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BookmarkGroup as BookmarkGroup
import Mutation.CreatePost as CreatePost
import Mutation.UnbookmarkGroup as UnbookmarkGroup
import Mutation.UpdateGroup as UpdateGroup
import Mutation.UpdateGroupMembership as UpdateGroupMembership
import Pagination
import Post exposing (Post)
import Query.FeaturedMemberships as FeaturedMemberships
import Query.GroupInit as GroupInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group exposing (Params(..))
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
import View.Layout exposing (spaceLayout)



-- MODEL


type EditorState
    = NotEditing
    | Editing
    | Submitting


type alias FieldEditor =
    { state : EditorState
    , value : String
    , errors : List ValidationError
    }


type alias PostComposer =
    { body : String
    , isSubmitting : Bool
    }


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , groupId : Id
    , featuredMemberIds : List Id
    , postComps : Connection Component.Post.Model
    , now : ( Zone, Posix )
    , nameEditor : FieldEditor
    , postComposer : PostComposer
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
            Connection.map buildPostComponent resp.postWithRepliesIds

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
                (FieldEditor NotEditing "" [])
                (PostComposer "" False)

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


buildPostComponent : ( Id, Connection Id ) -> Component.Post.Model
buildPostComponent ( postId, replyIds ) =
    Component.Post.init Component.Post.Feed False postId replyIds


setup : Model -> Cmd Msg
setup model =
    let
        pageCmd =
            Cmd.batch
                [ setFocus "post-composer" NoOp
                , Autosize.init "post-composer"
                , setupSockets model.groupId
                ]

        postsCmd =
            Connection.toList model.postComps
                |> List.map (\post -> Cmd.map (PostComponentMsg post.id) (Component.Post.setup post))
                |> Cmd.batch
    in
    Cmd.batch [ pageCmd, postsCmd ]


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
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, CreatePost.Response ))
    | MembershipStateToggled GroupMembershipState
    | MembershipStateSubmitted (Result Session.Error ( Session, UpdateGroupMembership.Response ))
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

        NewPostBodyChanged value ->
            let
                postComposer =
                    model.postComposer
            in
            { model | postComposer = { postComposer | body = value } }
                |> noCmd globals

        NewPostSubmit ->
            if newPostSubmittable model.postComposer then
                let
                    postComposer =
                        model.postComposer

                    cmd =
                        globals.session
                            |> CreatePost.request model.spaceId model.groupId postComposer.body
                            |> Task.attempt NewPostSubmitted
                in
                ( ( { model | postComposer = { postComposer | isSubmitting = True } }, cmd ), globals )

            else
                noCmd globals model

        NewPostSubmitted (Ok ( newSession, response )) ->
            let
                postComposer =
                    model.postComposer
            in
            ( ( { model | postComposer = { postComposer | body = "", isSubmitting = False } }
              , Autosize.update "post-composer"
              )
            , { globals | session = newSession }
            )

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewPostSubmitted (Err _) ->
            -- TODO: display error message
            let
                postComposer =
                    model.postComposer
            in
            { model | postComposer = { postComposer | isSubmitting = False } }
                |> noCmd globals

        MembershipStateToggled state ->
            let
                cmd =
                    globals.session
                        |> UpdateGroupMembership.request model.spaceId model.groupId state
                        |> Task.attempt MembershipStateSubmitted
            in
            ( ( model, cmd ), globals )

        MembershipStateSubmitted _ ->
            -- TODO: handle errors
            noCmd globals model

        NameClicked ->
            case resolveData globals.repo model of
                Just data ->
                    let
                        nameEditor =
                            model.nameEditor

                        newEditor =
                            { nameEditor | state = Editing, value = Group.name data.group, errors = [] }

                        cmd =
                            Cmd.batch
                                [ setFocus "name-editor-value" NoOp
                                , selectValue "name-editor-value"
                                ]
                    in
                    ( ( { model | nameEditor = newEditor }, cmd ), globals )

                Nothing ->
                    noCmd globals model

        NameEditorChanged val ->
            let
                nameEditor =
                    model.nameEditor
            in
            noCmd globals { model | nameEditor = { nameEditor | value = val } }

        NameEditorDismissed ->
            let
                nameEditor =
                    model.nameEditor
            in
            noCmd globals { model | nameEditor = { nameEditor | state = NotEditing } }

        NameEditorSubmit ->
            let
                nameEditor =
                    model.nameEditor

                cmd =
                    globals.session
                        |> UpdateGroup.request model.spaceId model.groupId (Just nameEditor.value) Nothing
                        |> Task.attempt NameEditorSubmitted
            in
            ( ( { model | nameEditor = { nameEditor | state = Submitting } }, cmd ), globals )

        NameEditorSubmitted (Ok ( newSession, UpdateGroup.Success newGroup )) ->
            let
                nameEditor =
                    model.nameEditor

                newModel =
                    { model | nameEditor = { nameEditor | state = NotEditing } }

                repo =
                    globals.repo
                        |> Repo.setGroup newGroup
            in
            noCmd { globals | session = newSession, repo = repo } newModel

        NameEditorSubmitted (Ok ( newSession, UpdateGroup.Invalid errors )) ->
            let
                nameEditor =
                    model.nameEditor
            in
            ( ( { model | nameEditor = { nameEditor | state = Editing, errors = errors } }
              , selectValue "name-editor-value"
              )
            , { globals | session = newSession }
            )

        NameEditorSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NameEditorSubmitted (Err _) ->
            let
                nameEditor =
                    model.nameEditor

                errors =
                    [ ValidationError "name" "Hmm, something went wrong." ]
            in
            ( ( { model | nameEditor = { nameEditor | state = Editing, errors = errors } }, Cmd.none )
            , globals
            )

        FeaturedMembershipsRefreshed (Ok ( newSession, memberships )) ->
            let
                memberIds =
                    memberships
                        |> List.map (SpaceUser.id << .user)
            in
            ( ( { model | featuredMemberIds = memberIds }, Cmd.none )
            , { globals | session = newSession }
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

        Event.GroupMembershipUpdated group ->
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
    every 1000 Tick



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
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ div [ class "scrolled-top-no-border sticky pin-t border-b py-4 bg-white z-50" ]
                    [ div [ class "flex items-center" ]
                        [ nameView data.group model.nameEditor
                        , bookmarkButtonView (Group.isBookmarked data.group)
                        , nameErrors model.nameEditor
                        , controlsView model
                        ]
                    ]
                , newPostView model.postComposer data.viewer
                , postsView repo data.space data.viewer model.now model.postComps
                , sidebarView data.group data.featuredMembers
                ]
            ]
        ]


nameView : Group -> FieldEditor -> Html Msg
nameView group editor =
    case editor.state of
        NotEditing ->
            h2 [ class "flex-no-shrink" ]
                [ span
                    [ onClick NameClicked
                    , class "font-extrabold text-2xl cursor-pointer"
                    ]
                    [ text (Group.name group) ]
                ]

        Editing ->
            h2 [ class "flex-no-shrink" ]
                [ input
                    [ type_ "text"
                    , id "name-editor-value"
                    , classList
                        [ ( "-ml-2 px-2 bg-grey-light font-extrabold text-2xl text-dusty-blue-darkest rounded no-outline js-stretchy", True )
                        , ( "shake", not <| List.isEmpty editor.errors )
                        ]
                    , value editor.value
                    , onInput NameEditorChanged
                    , onKeydown preventDefault
                        [ ( [], enter, \event -> NameEditorSubmit )
                        , ( [], esc, \event -> NameEditorDismissed )
                        ]
                    , onBlur NameEditorDismissed
                    ]
                    []
                ]

        Submitting ->
            h2 [ class "flex-no-shrink" ]
                [ input
                    [ type_ "text"
                    , class "-ml-2 px-2 bg-grey-light font-extrabold text-2xl text-dusty-blue-darkest rounded no-outline"
                    , value editor.value
                    , disabled True
                    ]
                    []
                ]


privacyToggle : Bool -> Html Msg
privacyToggle isPrivate =
    if isPrivate == True then
        button [ class "mx-2", onClick (PrivacyToggle False) ] [ Icons.lock ]

    else
        button [ class "mx-2", onClick (PrivacyToggle True) ] [ Icons.unlock ]


nameErrors : FieldEditor -> Html Msg
nameErrors editor =
    case ( editor.state, List.head editor.errors ) of
        ( Editing, Just error ) ->
            span [ class "ml-2 flex-grow text-sm text-red font-bold" ] [ text error.message ]

        ( _, _ ) ->
            text ""


controlsView : Model -> Html Msg
controlsView model =
    div [ class "flex flex-grow justify-end" ]
        [ paginationView model.params model.postComps
        ]


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (Route.Group << Route.Group.before params)
        (Route.Group << Route.Group.after params)


bookmarkButtonView : Bool -> Html Msg
bookmarkButtonView isBookmarked =
    if isBookmarked == True then
        button [ class "ml-3", onClick Unbookmark ]
            [ Icons.bookmark Icons.On ]

    else
        button [ class "ml-3", onClick Bookmark ]
            [ Icons.bookmark Icons.Off ]


newPostView : PostComposer -> SpaceUser -> Html Msg
newPostView ({ body, isSubmitting } as postComposer) currentUser =
    label [ class "composer mb-4" ]
        [ div [ class "flex" ]
            [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Medium currentUser ]
            , div [ class "flex-grow" ]
                [ textarea
                    [ id "post-composer"
                    , class "p-2 w-full h-10 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                    , placeholder "Compose a new post..."
                    , onInput NewPostBodyChanged
                    , onKeydown preventDefault [ ( [ Meta ], enter, \event -> NewPostSubmit ) ]
                    , readonly isSubmitting
                    , value body
                    ]
                    []
                , div [ class "flex justify-end" ]
                    [ button
                        [ class "btn btn-blue btn-md"
                        , onClick NewPostSubmit
                        , disabled (not (newPostSubmittable postComposer))
                        ]
                        [ text "Post message" ]
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


sidebarView : Group -> List SpaceUser -> Html Msg
sidebarView group featuredMembers =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "flex items-center mb-2 text-base font-extrabold" ]
            [ text "Members"
            , privacyToggle (Group.isPrivate group)
            ]
        , memberListView featuredMembers
        , subscribeButtonView (Group.membershipState group)
        ]


memberListView : List SpaceUser -> Html Msg
memberListView featuredMembers =
    if List.isEmpty featuredMembers then
        div [ class "pb-4 text-sm" ] [ text "Nobody has joined yet." ]

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
        NotSubscribed ->
            button
                [ class "text-sm text-blue"
                , onClick (MembershipStateToggled Subscribed)
                ]
                [ text "Join this group" ]

        Subscribed ->
            button
                [ class "text-sm text-blue"
                , onClick (MembershipStateToggled NotSubscribed)
                ]
                [ text "Leave this group" ]



-- UTILS


newPostSubmittable : PostComposer -> Bool
newPostSubmittable { body, isSubmitting } =
    not (body == "") && not isSubmitting
