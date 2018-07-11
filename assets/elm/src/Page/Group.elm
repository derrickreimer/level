module Page.Group
    exposing
        ( Model
        , Msg(..)
        , init
        , afterInit
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
import Data.Group exposing (Group)
import Data.GroupMembership exposing (GroupMembership, GroupMembershipState(..))
import Data.Post exposing (Post)
import Data.Reply exposing (Reply)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Data.ValidationError exposing (ValidationError)
import Keys exposing (Modifier(..), preventDefault, onKeydown, enter, esc)
import Mutation.PostToGroup as PostToGroup
import Mutation.UpdateGroup as UpdateGroup
import Mutation.UpdateGroupMembership as UpdateGroupMembership
import Ports
import Query.FeaturedMemberships as FeaturedMemberships
import Query.GroupInit as GroupInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import Subscription.GroupSubscription as GroupSubscription exposing (GroupMembershipUpdatedPayload)
import Subscription.PostSubscription as PostSubscription
import ViewHelpers exposing (setFocus, autosize, displayName, smartFormatDate, injectHtml, viewIf, viewUnless)


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
    , state : GroupMembershipState
    , posts : Connection Post
    , featuredMemberships : List GroupMembership
    , now : Date
    , space : Space
    , user : SpaceUser
    , nameEditor : FieldEditor
    , postComposer : PostComposer
    }



-- LIFECYCLE


init : SpaceUser -> Space -> String -> Session -> Task Session.Error ( Session, Model )
init user space groupId session =
    Date.now
        |> Task.andThen (GroupInit.task space.id groupId session)
        |> Task.andThen (buildModel user space)


buildModel : SpaceUser -> Space -> ( Session, GroupInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space ( session, { group, state, posts, featuredMemberships, now } ) =
    let
        model =
            { group = group
            , state = state
            , posts = posts
            , featuredMemberships = featuredMemberships
            , now = now
            , space = space
            , user = user
            , nameEditor = (FieldEditor NotEditing "" [])
            , postComposer = (PostComposer "" False)
            }
    in
        Task.succeed ( session, model )


afterInit : Model -> Cmd Msg
afterInit { group, posts } =
    Cmd.batch
        [ setFocus "post-composer" NoOp
        , autosize Autosize.Init "post-composer"
        , setupSockets group.id (Connection.toList posts)
        ]


teardown : Model -> Cmd Msg
teardown { group, posts } =
    teardownSockets group.id (Connection.toList posts)


setupSockets : String -> List Post -> Cmd Msg
setupSockets groupId posts =
    let
        groupSubscription =
            GroupSubscription.subscribe groupId

        postSubscriptions =
            posts
                |> List.map .id
                |> List.map PostSubscription.subscribe
    in
        groupSubscription
            :: postSubscriptions
            |> Cmd.batch


teardownSockets : String -> List Post -> Cmd Msg
teardownSockets groupId posts =
    let
        groupUnsubscribe =
            GroupSubscription.unsubscribe groupId

        postUnsubscribes =
            posts
                |> List.map .id
                |> List.map PostSubscription.unsubscribe
    in
        groupUnsubscribe
            :: postUnsubscribes
            |> Cmd.batch



-- UPDATE


type Msg
    = NoOp
    | Tick Time
    | NewPostBodyChanged String
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, PostToGroup.Response ))
    | MembershipStateToggled GroupMembershipState
    | MembershipStateSubmitted (Result Session.Error ( Session, UpdateGroupMembership.Response ))
    | NameClicked
    | NameEditorChanged String
    | NameEditorDismissed
    | NameEditorSubmit
    | NameEditorSubmitted (Result Session.Error ( Session, UpdateGroup.Response ))
    | FeaturedMembershipsRefreshed (Result Session.Error ( Session, FeaturedMemberships.Response ))
    | PostComponentMsg String Component.Post.Msg


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
                        PostToGroup.Params model.space.id model.group.id postComposer.body
                            |> PostToGroup.request
                            |> Session.request session
                            |> Task.attempt NewPostSubmitted
                in
                    ( ( { model | postComposer = { postComposer | isSubmitting = True } }, cmd ), session )
            else
                noCmd session model

        NewPostSubmitted (Ok ( session, response )) ->
            ( ( { model | postComposer = { postComposer | body = "", isSubmitting = False } }
              , autosize Autosize.Update "post-composer"
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
                    UpdateGroupMembership.Params model.space.id model.group.id state
                        |> UpdateGroupMembership.request
                        |> Session.request session
                        |> Task.attempt MembershipStateSubmitted
            in
                -- Update the state on the model optimistically
                ( ( { model | state = state }, cmd ), session )

        MembershipStateSubmitted _ ->
            -- TODO: handle errors
            noCmd session model

        NameClicked ->
            let
                group =
                    Repo.getGroup repo model.group

                newEditor =
                    { nameEditor | state = Editing, value = group.name, errors = [] }
            in
                ( ( { model | nameEditor = newEditor }
                  , Cmd.batch [ setFocus "name-editor-value" NoOp, Ports.select "name-editor-value" ]
                  )
                , session
                )

        NameEditorChanged val ->
            noCmd session { model | nameEditor = { nameEditor | value = val } }

        NameEditorDismissed ->
            noCmd session { model | nameEditor = { nameEditor | state = NotEditing } }

        NameEditorSubmit ->
            let
                cmd =
                    UpdateGroup.Params model.space.id model.group.id nameEditor.value
                        |> UpdateGroup.request
                        |> Session.request session
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
              , Ports.select "name-editor-value"
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
            case Connection.get postId model.posts of
                Just post ->
                    let
                        ( ( newPost, cmd ), newSession ) =
                            Component.Post.update msg model.space.id session post
                    in
                        ( ( { model | posts = Connection.update newPost model.posts }
                          , Cmd.map (PostComponentMsg postId) cmd
                          )
                        , newSession
                        )

                Nothing ->
                    noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )



-- EVENT HANDLERS


handlePostCreated : Post -> Model -> ( Model, Cmd Msg )
handlePostCreated post ({ posts, group } as model) =
    ( { model | posts = Connection.prepend post posts }
    , PostSubscription.subscribe post.id
    )


handleGroupMembershipUpdated : GroupMembershipUpdatedPayload -> Session -> Model -> ( Model, Cmd Msg )
handleGroupMembershipUpdated { state, membership } session model =
    let
        newState =
            if membership.user.id == model.user.id then
                state
            else
                model.state

        cmd =
            FeaturedMemberships.cmd
                model.space.id
                model.group.id
                session
                FeaturedMembershipsRefreshed
    in
        ( { model | state = newState }, cmd )


handleReplyCreated : Reply -> Model -> Model
handleReplyCreated ({ postId } as reply) ({ posts } as model) =
    case Connection.get postId posts of
        Just post ->
            let
                newPost =
                    Data.Post.appendReply reply post
            in
                { model | posts = Connection.update newPost posts }

        Nothing ->
            model


isMembershipListed : GroupMembership -> List GroupMembership -> Bool
isMembershipListed membership list =
    List.any (\m -> m.user.id == membership.user.id) list


removeMembership : GroupMembership -> List GroupMembership -> List GroupMembership
removeMembership membership list =
    List.filter (\m -> not (m.user.id == membership.user.id)) list



-- SUBSCRIPTION


subscriptions : Sub Msg
subscriptions =
    every second Tick



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    let
        group =
            Repo.getGroup repo model.group
    in
        div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ div [ class "group-header sticky pin-t border-b py-4 bg-white z-50" ]
                    [ div [ class "flex items-center" ]
                        [ nameView group model.nameEditor
                        , nameErrors model.nameEditor
                        , controlsView model.state
                        ]
                    ]
                , newPostView model.postComposer model.user group
                , postsView model.user model.now model.posts
                , sidebarView model.featuredMemberships
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
                    [ text group.name ]
                ]

        Editing ->
            h2 [ class "flex-no-shrink" ]
                [ input
                    [ type_ "text"
                    , id "name-editor-value"
                    , classList [ ( "-ml-2 px-2 bg-grey-light font-extrabold text-2xl text-dusty-blue-darkest rounded no-outline js-stretchy", True ), ( "shake", not <| List.isEmpty editor.errors ) ]
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


nameErrors : FieldEditor -> Html Msg
nameErrors editor =
    case ( editor.state, List.head editor.errors ) of
        ( Editing, Just error ) ->
            span [ class "ml-2 flex-grow text-sm text-red font-bold" ] [ text error.message ]

        ( _, _ ) ->
            text ""


controlsView : GroupMembershipState -> Html Msg
controlsView state =
    div [ class "flex flex-grow justify-end" ]
        [ subscribeButtonView state
        ]


subscribeButtonView : GroupMembershipState -> Html Msg
subscribeButtonView state =
    case state of
        NotSubscribed ->
            button
                [ class "btn btn-grey-outline btn-xs"
                , onClick (MembershipStateToggled Subscribed)
                ]
                [ text "Join" ]

        Subscribed ->
            button
                [ class "btn btn-turquoise-outline btn-xs"
                , onClick (MembershipStateToggled NotSubscribed)
                ]
                [ text "Member" ]


newPostView : PostComposer -> SpaceUser -> Group -> Html Msg
newPostView ({ body, isSubmitting } as postComposer) user group =
    label [ class "composer mb-4" ]
        [ div [ class "flex" ]
            [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Medium user ]
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


postsView : SpaceUser -> Date -> Connection Post -> Html Msg
postsView currentUser now connection =
    if Connection.isEmptyAndExpanded connection then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "Nobody has posted in this group yet." ]
    else
        div [] <|
            Connection.map (postView currentUser now) connection


postView : SpaceUser -> Date -> Post -> Html Msg
postView currentUser now post =
    Component.Post.view currentUser now post
        |> Html.map (PostComponentMsg post.id)


sidebarView : List GroupMembership -> Html Msg
sidebarView featuredMemberships =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-3 text-base" ] [ text "Members" ]
        , memberListView featuredMemberships
        ]


memberListView : List GroupMembership -> Html Msg
memberListView featuredMemberships =
    if List.isEmpty featuredMemberships then
        div [ class "text-sm" ] [ text "Nobody has joined yet." ]
    else
        div [] <| List.map memberItemView featuredMemberships


memberItemView : GroupMembership -> Html Msg
memberItemView { user } =
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny user ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| displayName user ]
        ]



-- UTILS


newPostSubmittable : PostComposer -> Bool
newPostSubmittable { body, isSubmitting } =
    not (body == "") && not isSubmitting
