module Page.Group
    exposing
        ( Model
        , Msg(..)
        , title
        , init
        , setup
        , teardown
        , update
        , subscriptions
        , view
        , handlePostCreated
        , handleReplyCreated
        , handleGroupMembershipUpdated
        )

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Time exposing (Time, every, second, millisecond)
import Autosize
import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import Data.GroupMembership exposing (GroupMembership, GroupMembershipState(..))
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Data.ValidationError exposing (ValidationError)
import Icons
import Keys exposing (Modifier(..), preventDefault, onKeydown, enter, esc)
import Mutation.BookmarkGroup as BookmarkGroup
import Mutation.UnbookmarkGroup as UnbookmarkGroup
import Mutation.CreatePost as CreatePost
import Mutation.UpdateGroup as UpdateGroup
import Mutation.UpdateGroupMembership as UpdateGroupMembership
import Query.FeaturedMemberships as FeaturedMemberships
import Query.GroupInit as GroupInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import Subscription.GroupSubscription as GroupSubscription
import TaskHelpers
import View.Helpers exposing (setFocus, selectValue, displayName, smartFormatDate, injectHtml, viewIf, viewUnless)


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
    { group : Group
    , posts : Connection Component.Post.Model
    , featuredMemberships : List GroupMembership
    , now : Date
    , space : Space
    , user : SpaceUser
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


init : SpaceUser -> Space -> String -> Session -> Task Session.Error ( Session, Model )
init user space groupId session =
    session
        |> GroupInit.request groupId
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.andThen (buildModel user space)


buildModel : SpaceUser -> Space -> ( ( Session, GroupInit.Response ), Date ) -> Task Session.Error ( Session, Model )
buildModel user space ( ( session, { group, posts, featuredMemberships } ), now ) =
    let
        model =
            Model
                group
                posts
                featuredMemberships
                now
                space
                user
                (FieldEditor NotEditing "" [])
                (PostComposer "" False)
    in
        Task.succeed ( session, model )


setup : Model -> Cmd Msg
setup { group, posts } =
    let
        pageCmd =
            Cmd.batch
                [ setFocus "post-composer" NoOp
                , Autosize.init "post-composer"
                , setupSockets (Group.getId group)
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
            teardownSockets (Group.getId group)

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
    | Tick Time
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


update : Msg -> Repo -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg repo session ({ postComposer, nameEditor } as model) =
    case msg of
        NoOp ->
            noCmd session model

        Tick time ->
            { model | now = Date.fromTime time }
                |> noCmd session

        NewPostBodyChanged value ->
            { model | postComposer = { postComposer | body = value } }
                |> noCmd session

        NewPostSubmit ->
            if newPostSubmittable postComposer then
                let
                    cmd =
                        CreatePost.request (Space.getId model.space) (Group.getId model.group) postComposer.body session
                            |> Task.attempt NewPostSubmitted
                in
                    ( ( { model | postComposer = { postComposer | isSubmitting = True } }, cmd ), session )
            else
                noCmd session model

        NewPostSubmitted (Ok ( session, response )) ->
            ( ( { model | postComposer = { postComposer | body = "", isSubmitting = False } }
              , Autosize.update "post-composer"
              )
            , session
            )

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NewPostSubmitted (Err _) ->
            -- TODO: display error message
            { model | postComposer = { postComposer | isSubmitting = False } }
                |> noCmd session

        MembershipStateToggled state ->
            let
                cmd =
                    UpdateGroupMembership.request (Space.getId model.space) (Group.getId model.group) state session
                        |> Task.attempt MembershipStateSubmitted
            in
                ( ( model, cmd ), session )

        MembershipStateSubmitted _ ->
            -- TODO: handle errors
            noCmd session model

        NameClicked ->
            let
                group =
                    Repo.getGroup repo model.group

                newEditor =
                    { nameEditor | state = Editing, value = group.name, errors = [] }

                cmd =
                    Cmd.batch
                        [ setFocus "name-editor-value" NoOp
                        , selectValue "name-editor-value"
                        ]
            in
                ( ( { model | nameEditor = newEditor }, cmd ), session )

        NameEditorChanged val ->
            noCmd session { model | nameEditor = { nameEditor | value = val } }

        NameEditorDismissed ->
            noCmd session { model | nameEditor = { nameEditor | state = NotEditing } }

        NameEditorSubmit ->
            let
                cmd =
                    UpdateGroup.request (Space.getId model.space) (Group.getId model.group) (Just nameEditor.value) Nothing session
                        |> Task.attempt NameEditorSubmitted
            in
                ( ( { model | nameEditor = { nameEditor | state = Submitting } }, cmd ), session )

        NameEditorSubmitted (Ok ( session, UpdateGroup.Success group )) ->
            let
                newModel =
                    { model
                        | group = group
                        , nameEditor = { nameEditor | state = NotEditing }
                    }
            in
                noCmd session newModel

        NameEditorSubmitted (Ok ( session, UpdateGroup.Invalid errors )) ->
            ( ( { model | nameEditor = { nameEditor | state = Editing, errors = errors } }
              , selectValue "name-editor-value"
              )
            , session
            )

        NameEditorSubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NameEditorSubmitted (Err _) ->
            let
                errors =
                    [ ValidationError "name" "Hmm, something went wrong." ]
            in
                ( ( { model | nameEditor = { nameEditor | state = Editing, errors = errors } }, Cmd.none )
                , session
                )

        FeaturedMembershipsRefreshed (Ok ( session, memberships )) ->
            ( ( { model | featuredMemberships = memberships }, Cmd.none ), session )

        FeaturedMembershipsRefreshed (Err Session.Expired) ->
            redirectToLogin session model

        FeaturedMembershipsRefreshed (Err _) ->
            noCmd session model

        PostComponentMsg postId msg ->
            case Connection.get .id postId model.posts of
                Just post ->
                    let
                        ( ( newPost, cmd ), newSession ) =
                            Component.Post.update msg (Space.getId model.space) session post
                    in
                        ( ( { model | posts = Connection.update .id newPost model.posts }
                          , Cmd.map (PostComponentMsg postId) cmd
                          )
                        , newSession
                        )

                Nothing ->
                    noCmd session model

        Bookmark ->
            let
                cmd =
                    session
                        |> BookmarkGroup.request (Space.getId model.space) (Group.getId model.group)
                        |> Task.attempt Bookmarked
            in
                ( ( model, cmd ), session )

        Bookmarked (Ok ( session, _ )) ->
            noCmd session { model | group = Group.setIsBookmarked True model.group }

        Bookmarked (Err Session.Expired) ->
            redirectToLogin session model

        Bookmarked (Err _) ->
            noCmd session model

        Unbookmark ->
            let
                cmd =
                    session
                        |> UnbookmarkGroup.request (Space.getId model.space) (Group.getId model.group)
                        |> Task.attempt Unbookmarked
            in
                ( ( model, cmd ), session )

        Unbookmarked (Ok ( session, _ )) ->
            noCmd session { model | group = Group.setIsBookmarked False model.group }

        Unbookmarked (Err Session.Expired) ->
            redirectToLogin session model

        Unbookmarked (Err _) ->
            noCmd session model

        PrivacyToggle isPrivate ->
            let
                cmd =
                    UpdateGroup.request (Space.getId model.space) (Group.getId model.group) Nothing (Just isPrivate) session
                        |> Task.attempt PrivacyToggled
            in
                ( ( model, cmd ), session )

        PrivacyToggled (Ok ( session, _ )) ->
            noCmd session model

        PrivacyToggled (Err Session.Expired) ->
            redirectToLogin session model

        PrivacyToggled (Err _) ->
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )



-- EVENT HANDLERS


handlePostCreated : Post -> Connection Reply -> Model -> ( Model, Cmd Msg )
handlePostCreated post replies ({ posts, group } as model) =
    let
        component =
            Component.Post.init Component.Post.Feed False post replies
    in
        ( { model | posts = Connection.prepend .id component posts }
        , Cmd.map (PostComponentMsg <| Post.getId post) (Component.Post.setup component)
        )


handleGroupMembershipUpdated : Group -> Session -> Model -> ( Model, Cmd Msg )
handleGroupMembershipUpdated group session model =
    if Group.getId group == Group.getId model.group then
        ( model
        , FeaturedMemberships.request (Group.getId model.group) session
            |> Task.attempt FeaturedMembershipsRefreshed
        )
    else
        ( model, Cmd.none )


handleReplyCreated : Reply -> Model -> ( Model, Cmd Msg )
handleReplyCreated reply ({ posts } as model) =
    let
        postId =
            Reply.getPostId reply
    in
        case Connection.get .id postId posts of
            Just component ->
                let
                    ( newComponent, cmd ) =
                        Component.Post.handleReplyCreated reply component
                in
                    ( { model | posts = Connection.update .id newComponent posts }
                    , Cmd.map (PostComponentMsg postId) cmd
                    )

            Nothing ->
                ( model, Cmd.none )



-- SUBSCRIPTION


subscriptions : Sub Msg
subscriptions =
    every second Tick



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    let
        currentUserData =
            model.user
                |> Repo.getSpaceUser repo

        groupData =
            model.group
                |> Repo.getGroup repo
    in
        div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ div [ class "scrolled-top-no-border sticky pin-t border-b py-4 bg-white z-50" ]
                    [ div [ class "flex items-center" ]
                        [ nameView groupData model.nameEditor
                        , privacyView groupData
                        , nameErrors model.nameEditor
                        , controlsView groupData.isBookmarked
                        ]
                    ]
                , newPostView model.postComposer currentUserData
                , postsView repo model.user model.now model.posts
                , sidebarView repo groupData.membershipState model.featuredMemberships
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


privacyView : Group.Record -> Html Msg
privacyView { isPrivate } =
    if isPrivate == True then
        button [ class "mx-3", onClick (PrivacyToggle False) ] [ Icons.lock ]
    else
        button [ class "mx-3", onClick (PrivacyToggle True) ] [ Icons.unlock ]


nameErrors : FieldEditor -> Html Msg
nameErrors editor =
    case ( editor.state, List.head editor.errors ) of
        ( Editing, Just error ) ->
            span [ class "ml-2 flex-grow text-sm text-red font-bold" ] [ text error.message ]

        ( _, _ ) ->
            text ""


controlsView : Bool -> Html Msg
controlsView isBookmarked =
    div [ class "flex flex-grow justify-end" ]
        [ bookmarkButtonView isBookmarked
        ]


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


postsView : Repo -> SpaceUser -> Date -> Connection Component.Post.Model -> Html Msg
postsView repo currentUser now connection =
    if Connection.isEmptyAndExpanded connection then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "Nobody has posted in this group yet." ]
    else
        div [] <|
            Connection.map (postView repo currentUser now) connection


postView : Repo -> SpaceUser -> Date -> Component.Post.Model -> Html Msg
postView repo currentUser now component =
    div [ class "p-4" ]
        [ Component.Post.postView repo currentUser now component
            |> Html.map (PostComponentMsg component.id)
        ]


sidebarView : Repo -> GroupMembershipState -> List GroupMembership -> Html Msg
sidebarView repo state featuredMemberships =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ] [ text "Members" ]
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
