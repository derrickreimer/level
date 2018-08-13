module Component.Mention
    exposing
        ( Model
        , Msg(..)
        , fragment
        , decoder
        , setup
        , teardown
        , update
        , handleReplyCreated
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Component.Post
import Connection exposing (Connection)
import Data.Mention as Mention exposing (Mention)
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Date exposing (Date)
import GraphQL exposing (Fragment)
import Icons
import Json.Decode as Decode exposing (Decoder, field, string)
import Repo exposing (Repo)
import Session exposing (Session)


-- MODEL


type alias Model =
    { id : String
    , mention : Mention
    , post : Component.Post.Model
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment MentionFields on Mention {
          id
          post {
            ...PostFields
            replies(last: 3) {
              ...ReplyConnectionFields
            }
          }
          mentioners {
            ...SpaceUserFields
          }
          lastOccurredAt
        }
        """
        [ Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        , SpaceUser.fragment
        ]


decoder : Decoder Model
decoder =
    Decode.map3 Model
        (field "id" string)
        (Mention.decoder)
        (field "post" (Component.Post.decoder Component.Post.Feed))



-- LIFECYCLE


setup : Model -> Cmd Msg
setup model =
    Component.Post.setup model.post
        |> Cmd.map PostComponentMsg


teardown : Model -> Cmd Msg
teardown model =
    Component.Post.teardown model.post
        |> Cmd.map PostComponentMsg



-- UPDATE


type Msg
    = PostComponentMsg Component.Post.Msg


update : Msg -> String -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg spaceId session model =
    case msg of
        PostComponentMsg msg ->
            let
                ( ( newPost, cmd ), newSession ) =
                    Component.Post.update msg spaceId session model.post
            in
                ( ( { model | post = newPost }
                  , Cmd.map PostComponentMsg cmd
                  )
                , newSession
                )



-- EVENT HANDLERS


handleReplyCreated : Reply -> Model -> ( Model, Cmd Msg )
handleReplyCreated reply model =
    let
        ( newPost, cmd ) =
            Component.Post.handleReplyCreated reply model.post
    in
        ( { model | post = newPost }
        , Cmd.map PostComponentMsg cmd
        )



-- VIEW


view : Repo -> SpaceUser -> Date -> Model -> Html Msg
view repo currentUser now { post } =
    div [ class "flex py-4" ]
        [ div [ class "flex-0" ]
            [ button [ class "flex items-center h-12 pr-4" ] [ Icons.checkSquare ]
            ]
        , div [ class "flex-1" ]
            [ postView repo currentUser now post
            ]
        ]


postView : Repo -> SpaceUser -> Date -> Component.Post.Model -> Html Msg
postView repo currentUser now postComponent =
    postComponent
        |> Component.Post.view repo currentUser now
        |> Html.map PostComponentMsg
