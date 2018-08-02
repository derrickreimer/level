module Query.PostInit exposing (Response, request)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Component.Post
import Connection exposing (Connection)
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { post : Component.Post.Model
    , now : Date
    }


document : Document
document =
    GraphQL.document
        """
        query PostInit(
          $spaceId: ID!
          $postId: ID!
        ) {
          space(id: $spaceId) {
            post(id: $postId) {
              ...PostFields
              replies(last: 20) {
                ...ReplyConnectionFields
              }
            }
          }
        }
        """
        [ Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceId postId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "postId", Encode.string postId )
            ]


decoder : Date -> Decoder Response
decoder now =
    Decode.at [ "data", "space", "post" ] <|
        Decode.map2 Response
            (Component.Post.decoder Component.Post.FullPage)
            (Decode.succeed now)


request : String -> String -> Session -> Date -> Task Session.Error ( Session, Response )
request spaceId postId session now =
    Session.request session <|
        GraphQL.request document (variables spaceId postId) (decoder now)
