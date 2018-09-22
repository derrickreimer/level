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
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BookmarkGroup as BookmarkGroup
import Mutation.CreatePost as CreatePost
import Mutation.UnbookmarkGroup as UnbookmarkGroup
import Mutation.UpdateGroup as UpdateGroup
import Mutation.UpdateGroupMembership as UpdateGroupMembership
import NewRepo exposing (NewRepo)
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
import View.Helpers exposing (displayName, selectValue, setFocus, smartFormatTime, viewIf, viewUnless)
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
    , viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    , posts : Connection Component.Post.Model
    , featuredMemberships : List GroupMembership
    , now : ( Zone, Posix )
    , nameEditor : FieldEditor
    , postComposer : PostComposer
    }



-- PAGE PROPERTIES


title : Repo -> Model -> String
title repo { group } =
    group
        |> Repo.getGroup repo
        |> .name



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
        model =
            Model
                params
                resp.viewer
                resp.space
                resp.bookmarks
                resp.group
                resp.posts
                resp.featuredMemberships
                now
                (FieldEditor NotEditing "" [])
                (PostComposer "" False)
    in
    ( { globals | session = newSession }, model )


setup : Model -> Cmd Msg
setup { group, posts } =
    let
        pageCmd =
            Cmd.batch
                [ setFocus "post-composer" NoOp
                , Autosize.init "post-composer"
                , setupSockets (Group.id group)
                ]

        postsCmd =
            Connection.toList posts
                |> List.map (\post -> Cmd.map (PostComponentMsg post.id) (Component.Post.setup post))
                |> Cmd.batch
    in
    Cmd.batch [ pageCmd, postsCmd ]


teardown : Model -> Cmd Msg
teardown { group, posts } =
    let
        pageCmd =
            teardownSockets (Group.id group)

        postsCmd =
            Connection.toList posts
                |> List.map (\post -> Cmd.map (PostComponentMsg post.id) (Component.Post.teardown post))
                |> Cmd.batch
    in
    Cmd.batch [ pageCmd, postsCmd ]


setupSockets : String -> Cmd Msg
setupSockets groupId =
    GroupSubscription.subscribe groupId


teardownSockets : String -> Cmd Msg
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
update msg globals ({ postComposer, nameEditor } as model) =
    case msg of
        NoOp ->
            noCmd globals model

        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), globals )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
                |> noCmd globals

        NewPostBodyChanged value ->
            { model | postComposer = { postComposer | body = value } }
                |> noCmd globals

        NewPostSubmit ->
            if newPostSubmittable postComposer then
                let
                    cmd =
                        globals.session
                            |> CreatePost.request (Space.id model.space) (Group.id model.group) postComposer.body
                            |> Task.attempt NewPostSubmitted
                in
                ( ( { model | postComposer = { postComposer | isSubmitting = True } }, cmd ), globals )

            else
                noCmd globals model

        NewPostSubmitted (Ok ( newSession, response )) ->
            ( ( { model | postComposer = { postComposer | body = "", isSubmitting = False } }
              , Autosize.update "post-composer"
              )
            , { globals | session = newSession }
            )

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewPostSubmitted (Err _) ->
            -- TODO: display error message
            { model | postComposer = { postComposer | isSubmitting = False } }
                |> noCmd globals

        MembershipStateToggled state ->
            let
                cmd =
                    globals.session
                        |> UpdateGroupMembership.request (Space.id model.space) (Group.id model.group) state
                        |> Task.attempt MembershipStateSubmitted
            in
            ( ( model, cmd ), globals )

        MembershipStateSubmitted _ ->
            -- TODO: handle errors
            noCmd globals model

        NameClicked ->
            let
                newEditor =
                    { nameEditor | state = Editing, value = Group.name model.group, errors = [] }

                cmd =
                    Cmd.batch
                        [ setFocus "name-editor-value" NoOp
                        , selectValue "name-editor-value"
                        ]
            in
            ( ( { model | nameEditor = newEditor }, cmd ), globals )

        NameEditorChanged val ->
            noCmd globals { model | nameEditor = { nameEditor | value = val } }

        NameEditorDismissed ->
            noCmd globals { model | nameEditor = { nameEditor | state = NotEditing } }

        NameEditorSubmit ->
            let
                cmd =
                    globals.session
                        |> UpdateGroup.request (Space.id model.space) (Group.id model.group) (Just nameEditor.value) Nothing
                        |> Task.attempt NameEditorSubmitted
            in
            ( ( { model | nameEditor = { nameEditor | state = Submitting } }, cmd ), globals )

        NameEditorSubmitted (Ok ( newSession, UpdateGroup.Success group )) ->
            let
                newModel =
                    { model
                        | group = group
                        , nameEditor = { nameEditor | state = NotEditing }
                    }
            in
            noCmd { globals | session = newSession } newModel

        NameEditorSubmitted (Ok ( newSession, UpdateGroup.Invalid errors )) ->
            ( ( { model | nameEditor = { nameEditor | state = Editing, errors = errors } }
              , selectValue "name-editor-value"
              )
            , { globals | session = newSession }
            )

        NameEditorSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NameEditorSubmitted (Err _) ->
            let
                errors =
                    [ ValidationError "name" "Hmm, something went wrong." ]
            in
            ( ( { model | nameEditor = { nameEditor | state = Editing, errors = errors } }, Cmd.none )
            , globals
            )

        FeaturedMembershipsRefreshed (Ok ( newSession, memberships )) ->
            ( ( { model | featuredMemberships = memberships }, Cmd.none )
            , { globals | session = newSession }
            )

        FeaturedMembershipsRefreshed (Err Session.Expired) ->
            redirectToLogin globals model

        FeaturedMembershipsRefreshed (Err _) ->
            noCmd globals model

        PostComponentMsg postId componentMsg ->
            case Connection.get .id postId model.posts of
                Just post ->
                    let
                        ( ( newPost, cmd ), newGlobals ) =
                            Component.Post.update componentMsg (Space.id model.space) globals post
                    in
                    ( ( { model | posts = Connection.update .id newPost model.posts }
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
                        |> BookmarkGroup.request (Space.id model.space) (Group.id model.group)
                        |> Task.attempt Bookmarked
            in
            ( ( model, cmd ), globals )

        Bookmarked (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession }
                { model | group = Group.setIsBookmarked True model.group }

        Bookmarked (Err Session.Expired) ->
            redirectToLogin globals model

        Bookmarked (Err _) ->
            noCmd globals model

        Unbookmark ->
            let
                cmd =
                    globals.session
                        |> UnbookmarkGroup.request (Space.id model.space) (Group.id model.group)
                        |> Task.attempt Unbookmarked
            in
            ( ( model, cmd ), globals )

        Unbookmarked (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession }
                { model | group = Group.setIsBookmarked False model.group }

        Unbookmarked (Err Session.Expired) ->
            redirectToLogin globals model

        Unbookmarked (Err _) ->
            noCmd globals model

        PrivacyToggle isPrivate ->
            let
                cmd =
                    globals.session
                        |> UpdateGroup.request (Space.id model.space) (Group.id model.group) Nothing (Just isPrivate)
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
            ( { model | bookmarks = insertUniqueBy Group.id group model.bookmarks }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarks = removeBy Group.id group model.bookmarks }, Cmd.none )

        Event.GroupMembershipUpdated group ->
            if Group.id group == Group.id model.group then
                ( model
                , FeaturedMemberships.request (Group.id model.group) session
                    |> Task.attempt FeaturedMembershipsRefreshed
                )

            else
                ( model, Cmd.none )

        Event.PostCreated ( post, replies ) ->
            let
                component =
                    Component.Post.init Component.Post.Feed False (Post.id post) (Connection.map Reply.id replies)
            in
            if Post.groupsInclude model.group post then
                ( { model | posts = Connection.prepend .id component model.posts }
                , Cmd.map (PostComponentMsg <| Post.id post) (Component.Post.setup component)
                )

            else
                ( model, Cmd.none )

        Event.ReplyCreated reply ->
            let
                postId =
                    Reply.postId reply
            in
            case Connection.get .id postId model.posts of
                Just component ->
                    let
                        ( newComponent, cmd ) =
                            Component.Post.handleReplyCreated reply component
                    in
                    ( { model | posts = Connection.update .id newComponent model.posts }
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
    let
        currentUserData =
            model.viewer
                |> Repo.getSpaceUser repo

        groupData =
            model.group
                |> Repo.getGroup repo
    in
    spaceLayout
        model.viewer
        model.space
        model.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ div [ class "scrolled-top-no-border sticky pin-t border-b py-4 bg-white z-50" ]
                    [ div [ class "flex items-center" ]
                        [ nameView groupData model.nameEditor
                        , bookmarkButtonView groupData.isBookmarked
                        , nameErrors model.nameEditor
                        , controlsView model
                        ]
                    ]
                , newPostView model.postComposer currentUserData
                , postsView model.space model.viewer model.now model.posts
                , sidebarView repo groupData.membershipState model.featuredMemberships groupData.isPrivate
                ]
            ]
        ]


nameView : Group.Record -> FieldEditor -> Html Msg
nameView groupData editor =
    case editor.state of
        NotEditing ->
            h2 [ class "flex-no-shrink" ]
                [ span
                    [ onClick NameClicked
                    , class "font-extrabold text-2xl cursor-pointer"
                    ]
                    [ text groupData.name ]
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
        [ paginationView model.space model.group model.posts
        ]


paginationView : Space -> Group -> Connection a -> Html Msg
paginationView space group connection =
    Pagination.view connection
        (Route.Group << Before (Space.slug space) (Group.id group))
        (Route.Group << After (Space.slug space) (Group.id group))


bookmarkButtonView : Bool -> Html Msg
bookmarkButtonView isBookmarked =
    if isBookmarked == True then
        button [ class "ml-3", onClick Unbookmark ]
            [ Icons.bookmark Icons.On ]

    else
        button [ class "ml-3", onClick Bookmark ]
            [ Icons.bookmark Icons.Off ]


newPostView : PostComposer -> SpaceUser.Record -> Html Msg
newPostView ({ body, isSubmitting } as postComposer) currentUserData =
    label [ class "composer mb-4" ]
        [ div [ class "flex" ]
            [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Medium currentUserData ]
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


postsView : Space -> SpaceUser -> ( Zone, Posix ) -> Connection Component.Post.Model -> Html Msg
postsView space currentUser now connection =
    if Connection.isEmptyAndExpanded connection then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "Be the first one to post here!" ]

    else
        div [] <|
            Connection.mapList (postView space currentUser now) connection


postView : Space -> SpaceUser -> ( Zone, Posix ) -> Component.Post.Model -> Html Msg
postView space currentUser now component =
    div [ class "p-4" ]
        [ Component.Post.view NewRepo.empty space currentUser now component
            |> Html.map (PostComponentMsg component.id)
        ]


sidebarView : Repo -> GroupMembershipState -> List GroupMembership -> Bool -> Html Msg
sidebarView repo state featuredMemberships isPrivate =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "flex items-center mb-2 text-base font-extrabold" ]
            [ text "Members"
            , privacyToggle isPrivate
            ]
        , memberListView repo featuredMemberships
        , subscribeButtonView state
        ]


memberListView : Repo -> List GroupMembership -> Html Msg
memberListView repo featuredMemberships =
    if List.isEmpty featuredMemberships then
        div [ class "pb-4 text-sm" ] [ text "Nobody has joined yet." ]

    else
        div [ class "pb-4" ] <| List.map (memberItemView repo) featuredMemberships


memberItemView : Repo -> GroupMembership -> Html Msg
memberItemView repo membership =
    let
        userData =
            Repo.getSpaceUser repo membership.user
    in
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny userData ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| displayName userData ]
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
