module Page.Group exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Dom exposing (focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline
import Task exposing (Task)
import Time exposing (Time, every, second, millisecond)
import Autosize
import Avatar exposing (personAvatar)
import Connection
import Data.Group exposing (Group, groupDecoder)
import Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipEdge
        , GroupMembershipConnection
        , GroupMembershipState(..)
        , groupMembershipConnectionDecoder
        , groupMembershipDecoder
        , groupMembershipStateDecoder
        )
import Data.Post exposing (Post, PostConnection, PostEdge, postConnectionDecoder)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Data.ValidationError exposing (ValidationError)
import GraphQL
import Icons
import Mutation.PostToGroup as PostToGroup
import Mutation.ReplyToPost as ReplyToPost
import Mutation.UpdateGroup as UpdateGroup
import Mutation.UpdateGroupMembership as UpdateGroupMembership
import Ports
import Query.FeaturedMemberships as FeaturedMemberships
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import Subscription.GroupMembershipUpdated as GroupMembershipUpdated
import Subscription.GroupUpdated as GroupUpdated
import Subscription.PostCreated as PostCreated
import Util exposing (displayName, smartFormatDate, memberById, onEnter, onEnterOrEsc, injectHtml, insertUniqueById, removeById)


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


type alias BootstrapResponse =
    { group : Group
    , state : GroupMembershipState
    , posts : PostConnection
    , featuredMemberships : List GroupMembership
    , now : Date
    }


type alias PostComposer =
    { body : String
    , isSubmitting : Bool
    }


type alias ReplyComposer =
    { body : String
    , isExpanded : Bool
    , isSubmitting : Bool
    }


type alias ReplyComposers =
    Dict String ReplyComposer


type alias Model =
    { group : Group
    , state : GroupMembershipState
    , posts : PostConnection
    , featuredMemberships : List GroupMembership
    , now : Date
    , space : Space
    , user : SpaceUser
    , nameEditor : FieldEditor
    , postComposer : PostComposer
    , replyComposers : ReplyComposers
    }



-- INIT


init : SpaceUser -> Space -> String -> Session -> Task Session.Error ( Session, Model )
init user space groupId session =
    Date.now
        |> Task.andThen (bootstrap space.id groupId session)
        |> Task.andThen (buildModel user space)


bootstrap : String -> String -> Session -> Date -> Task Session.Error ( Session, BootstrapResponse )
bootstrap spaceId groupId session now =
    let
        query =
            """
              query GroupInit(
                $spaceId: ID!
                $groupId: ID!
              ) {
                space(id: $spaceId) {
                  group(id: $groupId) {
                    id
                    name
                    membership {
                      state
                    }
                    featuredMemberships {
                      spaceUser {
                        id
                        firstName
                        lastName
                        role
                      }
                    }
                    posts(first: 20) {
                      edges {
                        node {
                          id
                          body
                          bodyHtml
                          postedAt
                          author {
                            id
                            firstName
                            lastName
                            role
                          }
                          groups {
                            id
                            name
                          }
                        }
                      }
                      pageInfo {
                        hasPreviousPage
                        hasNextPage
                        startCursor
                        endCursor
                      }
                    }
                  }
                }
              }
            """

        variables =
            Encode.object
                [ ( "spaceId", Encode.string spaceId )
                , ( "groupId", Encode.string groupId )
                ]

        decoder : Date -> Decode.Decoder BootstrapResponse
        decoder now =
            Decode.at [ "data", "space" ] <|
                (Pipeline.decode BootstrapResponse
                    |> Pipeline.custom (Decode.at [ "group" ] groupDecoder)
                    |> Pipeline.custom (Decode.at [ "group", "membership", "state" ] groupMembershipStateDecoder)
                    |> Pipeline.custom (Decode.at [ "group", "posts" ] postConnectionDecoder)
                    |> Pipeline.custom (Decode.at [ "group", "featuredMemberships" ] (Decode.list groupMembershipDecoder))
                    |> Pipeline.custom (Decode.succeed now)
                )
    in
        GraphQL.request query (Just variables) (decoder now)
            |> Session.request session


buildModel : SpaceUser -> Space -> ( Session, BootstrapResponse ) -> Task Session.Error ( Session, Model )
buildModel user space ( session, { group, state, posts, featuredMemberships, now } ) =
    let
        model =
            Model
                group
                state
                posts
                featuredMemberships
                now
                space
                user
                (FieldEditor NotEditing "" [])
                (PostComposer "" False)
                Dict.empty
    in
        Task.succeed ( session, model )


afterInit : Model -> Cmd Msg
afterInit { group } =
    Cmd.batch
        [ setFocus "post-composer"
        , autosize Autosize.Init "post-composer"
        , setupSockets group.id
        ]


teardown : Model -> Cmd Msg
teardown { group } =
    teardownSockets group.id



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
    | ExpandReplyComposer String
    | NewReplyBodyChanged String String
    | NewReplySubmit String
    | NewReplySubmitted (Result Session.Error ( Session, ReplyToPost.Response ))


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
                  , Cmd.batch [ setFocus "name-editor-value", Ports.select "name-editor-value" ]
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

        ExpandReplyComposer postId ->
            let
                nodeId =
                    replyComposerId postId

                cmd =
                    Cmd.batch
                        [ setFocus nodeId
                        , autosize Autosize.Init nodeId
                        ]

                newReplyComposers =
                    case Dict.get postId model.replyComposers of
                        Just composer ->
                            Dict.insert postId { composer | isExpanded = True } model.replyComposers

                        Nothing ->
                            Dict.insert postId (ReplyComposer "" True False) model.replyComposers
            in
                ( ( { model | replyComposers = newReplyComposers }, cmd ), session )

        NewReplyBodyChanged postId val ->
            case Dict.get postId model.replyComposers of
                Just composer ->
                    let
                        replyComposers =
                            Dict.insert postId { composer | body = val } model.replyComposers
                    in
                        noCmd session { model | replyComposers = replyComposers }

                Nothing ->
                    noCmd session model

        NewReplySubmit postId ->
            case Dict.get postId model.replyComposers of
                Just composer ->
                    let
                        replyComposers =
                            Dict.insert postId { composer | isSubmitting = True } model.replyComposers

                        cmd =
                            ReplyToPost.Params model.space.id postId composer.body
                                |> ReplyToPost.request
                                |> Session.request session
                                |> Task.attempt NewReplySubmitted
                    in
                        ( ( { model | replyComposers = replyComposers }, cmd ), session )

                Nothing ->
                    noCmd session model

        NewReplySubmitted (Ok ( session, response )) ->
            noCmd session model

        NewReplySubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NewReplySubmitted (Err _) ->
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


setupSockets : String -> Cmd Msg
setupSockets groupId =
    let
        payloads =
            [ PostCreated.payload groupId
            , GroupMembershipUpdated.payload groupId
            , GroupUpdated.payload groupId
            ]
    in
        payloads
            |> List.map Ports.push
            |> Cmd.batch


teardownSockets : String -> Cmd Msg
teardownSockets groupId =
    let
        payloads =
            [ PostCreated.clientId groupId
            , GroupMembershipUpdated.clientId groupId
            ]
    in
        payloads
            |> List.map Ports.cancel
            |> Cmd.batch


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )


setFocus : String -> Cmd Msg
setFocus id =
    Task.attempt (always NoOp) <| focus id


autosize : Autosize.Method -> String -> Cmd Msg
autosize method id =
    Ports.autosize (Autosize.buildArgs method id)



-- EVENT HANDLERS


handlePostCreated : PostCreated.Data -> Model -> Model
handlePostCreated { post } model =
    let
        newPosts =
            if memberById model.group post.groups then
                Data.Post.add post model.posts
            else
                model.posts
    in
        { model | posts = newPosts }


handleGroupMembershipUpdated : GroupMembershipUpdated.Data -> Session -> Model -> ( Model, Cmd Msg )
handleGroupMembershipUpdated { state, membership } session model =
    let
        newState =
            if membership.user.id == model.user.id then
                state
            else
                model.state

        cmd =
            FeaturedMemberships.Params model.space.id model.group.id
                |> FeaturedMemberships.request
                |> Session.request session
                |> Task.attempt FeaturedMembershipsRefreshed
    in
        ( { model | state = newState }, cmd )


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
                , postListView model.user model.now model.replyComposers model.posts
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
                    , onEnterOrEsc NameEditorSubmit NameEditorDismissed
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
                    , onEnter True NewPostSubmit
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


postListView : SpaceUser -> Date -> ReplyComposers -> PostConnection -> Html Msg
postListView currentUser now replyComposers ({ nodes } as connection) =
    if Connection.isEmpty connection then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "Nobody has posted in this group yet." ]
    else
        div [] <|
            List.map (postView currentUser now replyComposers) nodes


postView : SpaceUser -> Date -> ReplyComposers -> Post -> Html Msg
postView currentUser now replyComposers post =
    div [ class "flex p-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ personAvatar Avatar.Medium post.author ]
        , div [ class "flex-grow leading-semi-loose" ]
            [ div []
                [ span [ class "font-bold" ] [ text <| displayName post.author ]
                , span [ class "ml-3 text-sm text-dusty-blue" ] [ text <| smartFormatDate now post.postedAt ]
                ]
            , div [ class "markdown mb-2" ] [ injectHtml post.bodyHtml ]
            , div [ class "flex items-center" ]
                [ div [ class "flex-grow" ]
                    [ button [ class "inline-block mr-4", onClick (ExpandReplyComposer post.id) ] [ Icons.comment ]
                    ]
                ]
            , replyComposerView currentUser replyComposers post
            ]
        ]


replyComposerView : SpaceUser -> ReplyComposers -> Post -> Html Msg
replyComposerView currentUser replyComposers post =
    case Dict.get post.id replyComposers of
        Just composer ->
            div [ class "composer mt-2 -ml-3 p-3" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-no-shrink mr-1" ] [ personAvatar Avatar.Small currentUser ]
                    , div [ class "flex-grow" ]
                        [ textarea
                            [ id (replyComposerId post.id)
                            , class "p-2 w-full h-10 no-outline bg-transparent text-dusty-blue-darkest text-sm resize-none leading-normal"
                            , placeholder "Write a reply..."
                            , onInput (NewReplyBodyChanged post.id)
                            , onEnter True (NewReplySubmit post.id)
                            , value composer.body
                            , readonly composer.isSubmitting
                            ]
                            []
                        , div [ class "flex justify-end" ]
                            [ button
                                [ class "btn btn-blue btn-sm"
                                , onClick (NewReplySubmit post.id)
                                , disabled (not (newReplySubmittable composer))
                                ]
                                [ text "Post reply" ]
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""


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


newReplySubmittable : ReplyComposer -> Bool
newReplySubmittable { body, isSubmitting } =
    not (body == "") && not isSubmitting


replyComposerId : String -> String
replyComposerId postId =
    "reply-composer-" ++ postId
