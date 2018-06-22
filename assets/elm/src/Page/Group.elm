module Page.Group exposing (..)

import Date exposing (Date)
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
import Mutation.PostToGroup as PostToGroup
import Mutation.UpdateGroup as UpdateGroup
import Mutation.UpdateGroupMembership as UpdateGroupMembership
import Ports
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


type alias Model =
    { group : Group
    , space : Space
    , user : SpaceUser
    , state : GroupMembershipState
    , posts : PostConnection
    , featuredMemberships : List GroupMembership
    , newPostBody : String
    , isNewPostSubmitting : Bool
    , nameEditor : FieldEditor
    , now : Date
    }



-- INIT


init : Space -> SpaceUser -> String -> Session -> Task Session.Error ( Session, Model )
init space user groupId session =
    Date.now
        |> Task.andThen (bootstrap space user groupId session)


bootstrap : Space -> SpaceUser -> String -> Session -> Date -> Task Session.Error ( Session, Model )
bootstrap space user groupId session now =
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
                [ ( "spaceId", Encode.string space.id )
                , ( "groupId", Encode.string groupId )
                ]

        decoder : Space -> SpaceUser -> Date -> Decode.Decoder Model
        decoder space user now =
            Decode.at [ "data", "space" ] <|
                (Pipeline.decode Model
                    |> Pipeline.custom (Decode.at [ "group" ] groupDecoder)
                    |> Pipeline.custom (Decode.succeed space)
                    |> Pipeline.custom (Decode.succeed user)
                    |> Pipeline.custom (Decode.at [ "group", "membership", "state" ] groupMembershipStateDecoder)
                    |> Pipeline.custom (Decode.at [ "group", "posts" ] postConnectionDecoder)
                    |> Pipeline.custom (Decode.at [ "group", "featuredMemberships" ] (Decode.list groupMembershipDecoder))
                    |> Pipeline.custom (Decode.succeed "")
                    |> Pipeline.custom (Decode.succeed False)
                    |> Pipeline.custom (Decode.succeed (FieldEditor NotEditing "" []))
                    |> Pipeline.custom (Decode.succeed now)
                )
    in
        GraphQL.request query (Just variables) (decoder space user now)
            |> Session.request session


afterInit : Model -> Cmd Msg
afterInit model =
    Cmd.batch
        [ setFocus "post-composer"
        , autosize Autosize.Init "post-composer"
        , setupSockets model.group
        ]


teardown : Model -> Cmd Msg
teardown model =
    teardownSockets model.group



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


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        NoOp ->
            noCmd session model

        Tick time ->
            { model | now = Date.fromTime time }
                |> noCmd session

        NewPostBodyChanged value ->
            { model | newPostBody = value }
                |> noCmd session

        NewPostSubmit ->
            if newPostSubmittable model.newPostBody then
                let
                    cmd =
                        PostToGroup.Params model.space.id model.group.id model.newPostBody
                            |> PostToGroup.request
                            |> Session.request session
                            |> Task.attempt NewPostSubmitted
                in
                    ( ( { model | isNewPostSubmitting = True }, cmd ), session )
            else
                noCmd session model

        NewPostSubmitted (Ok ( session, response )) ->
            ( ( { model | newPostBody = "", isNewPostSubmitting = False }
              , autosize Autosize.Update "post-composer"
              )
            , session
            )

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NewPostSubmitted (Err _) ->
            -- TODO: display error message
            { model | isNewPostSubmitting = False }
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
                editor =
                    model.nameEditor

                newEditor =
                    { editor | state = Editing, value = model.group.name, errors = [] }
            in
                ( ( { model | nameEditor = newEditor }
                  , Cmd.batch [ setFocus "name-editor-value", Ports.select "name-editor-value" ]
                  )
                , session
                )

        NameEditorChanged val ->
            let
                editor =
                    model.nameEditor
            in
                noCmd session { model | nameEditor = { editor | value = val } }

        NameEditorDismissed ->
            let
                editor =
                    model.nameEditor
            in
                noCmd session { model | nameEditor = { editor | state = NotEditing } }

        NameEditorSubmit ->
            let
                editor =
                    model.nameEditor

                cmd =
                    UpdateGroup.Params model.space.id model.group.id editor.value
                        |> UpdateGroup.request
                        |> Session.request session
                        |> Task.attempt NameEditorSubmitted
            in
                ( ( { model | nameEditor = { editor | state = Submitting } }, cmd ), session )

        NameEditorSubmitted (Ok ( session, UpdateGroup.Success group )) ->
            let
                editor =
                    model.nameEditor

                newModel =
                    { model
                        | group = group
                        , nameEditor = { editor | state = NotEditing }
                    }
            in
                noCmd session newModel

        NameEditorSubmitted (Ok ( session, UpdateGroup.Invalid errors )) ->
            let
                editor =
                    model.nameEditor
            in
                ( ( { model | nameEditor = { editor | state = Editing, errors = errors } }
                  , Ports.select "name-editor-value"
                  )
                , session
                )

        NameEditorSubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NameEditorSubmitted (Err _) ->
            let
                editor =
                    model.nameEditor

                errors =
                    [ ValidationError "name" "Hmm, something went wrong." ]
            in
                ( ( { model | nameEditor = { editor | state = Editing, errors = errors } }, Cmd.none )
                , session
                )


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


setupSockets : Group -> Cmd Msg
setupSockets group =
    let
        payloads =
            [ PostCreated.payload group.id
            , GroupMembershipUpdated.payload group.id
            , GroupUpdated.payload group.id
            ]
    in
        payloads
            |> List.map Ports.push
            |> Cmd.batch


teardownSockets : Group -> Cmd Msg
teardownSockets group =
    let
        payloads =
            [ PostCreated.clientId group.id
            , GroupMembershipUpdated.clientId group.id
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


newPostSubmittable : String -> Bool
newPostSubmittable body =
    not (body == "")



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


handleGroupMembershipUpdated : GroupMembershipUpdated.Data -> Model -> Model
handleGroupMembershipUpdated { state, membership } model =
    let
        newFeaturedMemberships =
            case state of
                NotSubscribed ->
                    removeMembership membership model.featuredMemberships

                Subscribed ->
                    if isMembershipListed membership model.featuredMemberships then
                        model.featuredMemberships
                    else
                        membership :: model.featuredMemberships
    in
        { model | featuredMemberships = newFeaturedMemberships }


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


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ div [ class "group-header sticky pin-t border-b py-4 bg-white z-50" ]
                [ div [ class "flex items-center" ]
                    [ nameView model.group model.nameEditor
                    , nameErrors model.nameEditor
                    , controlsView model.state
                    ]
                ]
            , newPostView model.newPostBody model.user model.group
            , postListView model.user model.posts model.now
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


newPostView : String -> SpaceUser -> Group -> Html Msg
newPostView body user group =
    label [ class "composer mb-4 border" ]
        [ div [ class "flex" ]
            [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Medium user ]
            , div [ class "flex-grow" ]
                [ textarea
                    [ id "post-composer"
                    , class "p-2 w-full h-10 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                    , placeholder "Compose a new post..."
                    , onInput NewPostBodyChanged
                    , onEnter True NewPostSubmit
                    , value body
                    ]
                    []
                , div [ class "flex justify-end" ]
                    [ button
                        [ class "btn btn-blue btn-sm"
                        , onClick NewPostSubmit
                        , disabled (not (newPostSubmittable body))
                        ]
                        [ text "Post message" ]
                    ]
                ]
            ]
        ]


postListView : SpaceUser -> PostConnection -> Date -> Html Msg
postListView currentUser ({ edges } as connection) now =
    if Connection.isEmpty connection then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "Nobody has posted in this group yet." ]
    else
        div [] <|
            List.map (postView currentUser now) edges


postView : SpaceUser -> Date -> PostEdge -> Html Msg
postView currentUser now { node } =
    div [ class "flex p-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ personAvatar Avatar.Medium node.author ]
        , div [ class "flex-grow leading-semi-loose" ]
            [ div []
                [ span [ class "font-bold" ] [ text <| displayName node.author ]
                , span [ class "ml-3 text-sm text-dusty-blue" ] [ text <| smartFormatDate now node.postedAt ]
                ]
            , div [ class "markdown mb-1" ] [ injectHtml node.bodyHtml ]
            , div [ class "flex items-center" ]
                [ div [ class "flex-grow" ]
                    [ span [ class "text-dusty-blue text-sm" ] [ text "Add a comment..." ]
                    ]
                ]
            ]
        ]


sidebarView : List GroupMembership -> Html Msg
sidebarView featuredMemberships =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-3 text-base" ] [ text "Members" ]
        , div [] <|
            List.map memberItemView featuredMemberships
        ]


memberItemView : GroupMembership -> Html Msg
memberItemView { user } =
    div [ class "flex items-center mb-1" ]
        [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny user ]
        , div [ class "flex-grow text-sm" ] [ text <| displayName user ]
        ]
