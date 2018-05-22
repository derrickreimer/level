module Page.Group exposing (..)

import Dom exposing (focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline
import Task exposing (Task)
import Avatar exposing (personAvatar)
import Data.Group exposing (Group, groupDecoder)
import Data.Post exposing (PostConnection, PostEdge, postConnectionDecoder)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import GraphQL
import Mutation.PostToGroup as PostToGroup
import Route
import Session exposing (Session)
import Util exposing (displayName, formatTime)


-- MODEL


type alias Model =
    { group : Group
    , space : Space
    , user : SpaceUser
    , posts : PostConnection
    , newPostBody : String
    , isNewPostSubmitting : Bool
    }



-- INIT


init : Space -> SpaceUser -> String -> Session -> Task Session.Error ( Session, Model )
init space user groupId session =
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
                    posts(first: 20) {
                      edges {
                        node {
                          id
                          body
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
    in
        GraphQL.request query (Just variables) (decoder space user)
            |> Session.request session


decoder : Space -> SpaceUser -> Decode.Decoder Model
decoder space user =
    Decode.at [ "data", "space" ] <|
        (Pipeline.decode Model
            |> Pipeline.custom (Decode.at [ "group" ] groupDecoder)
            |> Pipeline.custom (Decode.succeed space)
            |> Pipeline.custom (Decode.succeed user)
            |> Pipeline.custom (Decode.at [ "group", "posts" ] postConnectionDecoder)
            |> Pipeline.custom (Decode.succeed "")
            |> Pipeline.custom (Decode.succeed False)
        )


initialized : Cmd Msg
initialized =
    setFocus "post-composer"



-- UPDATE


type Msg
    = NoOp
    | NewPostBodyChanged String
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, PostToGroup.Response ))


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        NoOp ->
            noOp session model

        NewPostBodyChanged value ->
            noOp session { model | newPostBody = value }

        NewPostSubmit ->
            let
                cmd =
                    PostToGroup.Params model.space.id model.group.id model.newPostBody
                        |> PostToGroup.request
                        |> Session.request session
                        |> Task.attempt NewPostSubmitted
            in
                ( ( { model | isNewPostSubmitting = True }, cmd ), session )

        NewPostSubmitted (Ok ( session, response )) ->
            -- TODO: clear the form
            noOp session { model | isNewPostSubmitting = False }

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NewPostSubmitted (Err _) ->
            noOp session { model | isNewPostSubmitting = False }


noOp : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noOp session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )


setFocus : String -> Cmd Msg
setFocus id =
    Task.attempt (always NoOp) <| focus id



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto pt-4 max-w-90 leading-normal" ]
            [ h2 [ class "mb-4 font-extrabold text-2xl" ] [ text model.group.name ]
            , newPostView model.newPostBody model.user model.group
            , postListView model.posts.edges
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
                    , class "p-2 w-full h-10 no-outline bg-transparent text-dusty-blue-darker resize-none leading-normal"
                    , placeholder "Compose a new post..."
                    , onInput NewPostBodyChanged
                    , value body
                    ]
                    []
                , div [ class "flex justify-end" ]
                    [ button [ class "btn btn-blue btn-sm", onClick NewPostSubmit ] [ text "Post message" ] ]
                ]
            ]
        ]


postListView : List PostEdge -> Html Msg
postListView edges =
    div [] <|
        List.map postView edges


postView : PostEdge -> Html Msg
postView { node } =
    div [ class "flex p-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ personAvatar Avatar.Medium node.author ]
        , div [ class "flex-grow leading-semi-loose" ]
            [ div []
                [ span [ class "font-bold" ] [ text <| displayName node.author ]
                , span [ class "ml-3 text-sm text-dusty-blue-dark" ] [ text <| formatTime node.postedAt ]
                ]
            , div [ class "leading-normal" ] [ text node.body ]
            ]
        ]
