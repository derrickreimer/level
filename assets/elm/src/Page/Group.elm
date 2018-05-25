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
import Data.Group exposing (Group, groupDecoder)
import Data.GroupMembership
    exposing
        ( GroupMembership
        , GroupMembershipEdge
        , GroupMembershipConnection
        , GroupSubscriptionLevel
        , groupMembershipConnectionDecoder
        , groupSubscriptionLevelDecoder
        )
import Data.Post exposing (Post, PostConnection, PostEdge, postConnectionDecoder)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import GraphQL
import Mutation.PostToGroup as PostToGroup
import Ports
import Route
import Session exposing (Session)
import Subscription.PostCreated as PostCreated
import Util exposing (displayName, smartFormatDate, memberById, onEnter)


-- MODEL


type alias Model =
    { group : Group
    , space : Space
    , user : SpaceUser
    , subscriptionLevel : GroupSubscriptionLevel
    , posts : PostConnection
    , members : GroupMembershipConnection
    , newPostBody : String
    , isNewPostSubmitting : Bool
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
                      subscriptionLevel
                    }
                    memberships(first: 10) {
                      edges {
                        node {
                          spaceUser {
                            id
                            firstName
                            lastName
                            role
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
                    |> Pipeline.custom (Decode.at [ "group", "membership" ] groupSubscriptionLevelDecoder)
                    |> Pipeline.custom (Decode.at [ "group", "posts" ] postConnectionDecoder)
                    |> Pipeline.custom (Decode.at [ "group", "memberships" ] groupMembershipConnectionDecoder)
                    |> Pipeline.custom (Decode.succeed "")
                    |> Pipeline.custom (Decode.succeed False)
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


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


setupSockets : Group -> Cmd Msg
setupSockets group =
    let
        payloads =
            [ PostCreated.payload group.id
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


receivePost : Post -> Model -> Model
receivePost ({ groups } as post) model =
    if memberById model.group groups then
        { model | posts = (addPostToConnection post model.posts) }
    else
        model


addPostToConnection : Post -> PostConnection -> PostConnection
addPostToConnection post connection =
    let
        edges =
            connection.edges
    in
        if List.any (\{ node } -> node.id == post.id) edges then
            connection
        else
            { connection | edges = (PostEdge post) :: edges }


newPostSubmittable : String -> Bool
newPostSubmittable body =
    not (body == "")



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
                    [ h2 [ class "flex-grow font-extrabold text-2xl" ] [ text model.group.name ]
                    , button [ class "btn btn-grey-outline btn-xs" ] [ text "Subscribe" ]
                    ]
                ]
            , newPostView model.newPostBody model.user model.group
            , postListView model.user model.posts.edges model.now
            , sidebarView model.members
            ]
        ]


newPostView : String -> SpaceUser -> Group -> Html Msg
newPostView body user group =
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


postListView : SpaceUser -> List PostEdge -> Date -> Html Msg
postListView currentUser edges now =
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


sidebarView : GroupMembershipConnection -> Html Msg
sidebarView { edges } =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l border-grey-light min-h-half" ]
        [ h3 [ class "mb-3 text-base" ] [ text "Members" ]
        , memberListView edges
        ]


memberListView : List GroupMembershipEdge -> Html Msg
memberListView edges =
    div [] <|
        List.map memberItemView (List.map .node edges)


memberItemView : GroupMembership -> Html Msg
memberItemView { user } =
    div [ class "flex items-center" ]
        [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny user ]
        , div [ class "flex-grow text-sm" ] [ text <| displayName user ]
        ]


injectHtml : String -> Html msg
injectHtml rawHtml =
    div [ property "innerHTML" <| Encode.string rawHtml ] []
