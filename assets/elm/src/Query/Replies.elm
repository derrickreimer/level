module Query.Replies exposing (Params, Response, task)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Reply exposing (Reply)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Params =
    { spaceId : String
    , postId : String
    , before : String
    , limit : Int
    }


type alias Response =
    { replies : Connection Reply
    }


document : Document
document =
    GraphQL.document
        """
        query PostInit(
          $spaceId: ID!
          $postId: ID!
          $before: Cursor!
          $limit: Int!
        ) {
          space(id: $spaceId) {
            post(id: $postId) {
              replies(last: $limit, before: $before) {
                ...ReplyConnectionFields
              }
            }
          }
        }
        """
        [ Connection.fragment "ReplyConnection" Data.Reply.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string params.spaceId )
            , ( "postId", Encode.string params.postId )
            , ( "before", Encode.string params.before )
            , ( "limit", Encode.int params.limit )
            ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "space", "post", "replies" ] <|
        Decode.map Response (Connection.decoder Data.Reply.decoder)


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    Session.request session <|
        GraphQL.request document (variables params) decoder


task : String -> String -> String -> Int -> Session -> Task Session.Error ( Session, Response )
task spaceId postId before limit session =
    request (Params spaceId postId before limit) session
