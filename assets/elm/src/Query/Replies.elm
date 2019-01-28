module Query.Replies exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field)
import Json.Encode as Encode
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedReply exposing (ResolvedReply)
import Session exposing (Session)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { replyIds : Connection Id
    , repo : Repo
    }


type alias Data =
    Connection ResolvedReply


document : Document
document =
    GraphQL.toDocument
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
        [ Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : Id -> Id -> String -> Int -> Maybe Encode.Value
variables spaceId postId before limit =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "postId", Id.encoder postId )
            , ( "before", Encode.string before )
            , ( "limit", Encode.int limit )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "space", "post", "replies" ] <|
        Connection.decoder ResolvedReply.decoder


addRepliesToRepo : Connection ResolvedReply -> Repo -> Repo
addRepliesToRepo conn repo =
    ResolvedReply.addManyToRepo (Connection.toList conn) repo


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        resp =
            Response
                (Connection.map (Reply.id << .reply) data)
                (addRepliesToRepo data Repo.empty)
    in
    ( session, resp )


request : Id -> Id -> String -> Int -> Session -> Task Session.Error ( Session, Response )
request spaceId postId before limit session =
    GraphQL.request document (variables spaceId postId before limit) decoder
        |> Session.request session
        |> Task.map buildResponse
