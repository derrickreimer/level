module Query.Replies exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder, field)
import Json.Encode as Encode
import NewRepo exposing (NewRepo)
import Reply exposing (Reply)
import Session exposing (Session)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { replyIds : Connection String
    , repo : NewRepo
    }


type alias Data =
    Connection ResolvedReply


type alias ResolvedReply =
    { reply : Reply
    , author : SpaceUser
    }


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


variables : String -> String -> String -> Int -> Maybe Encode.Value
variables spaceId postId before limit =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "postId", Encode.string postId )
            , ( "before", Encode.string before )
            , ( "limit", Encode.int limit )
            ]


resolvedReplyDecoder : Decoder ResolvedReply
resolvedReplyDecoder =
    Decode.map2 ResolvedReply
        Reply.decoder
        (field "author" SpaceUser.decoder)


decoder : Decoder Data
decoder =
    Decode.at [ "data", "space", "post", "replies" ] <|
        Connection.decoder resolvedReplyDecoder


addRepliesToRepo : Connection ResolvedReply -> NewRepo -> NewRepo
addRepliesToRepo resolvedReplies repo =
    let
        reducer resolvedReply acc =
            acc
                |> NewRepo.setReply resolvedReply.reply
                |> NewRepo.setSpaceUser resolvedReply.author
    in
    List.foldr reducer repo (Connection.toList resolvedReplies)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        resp =
            Response
                (Connection.map (Reply.id << .reply) data)
                (addRepliesToRepo data NewRepo.empty)
    in
    ( session, resp )


request : String -> String -> String -> Int -> Session -> Task Session.Error ( Session, Response )
request spaceId postId before limit session =
    GraphQL.request document (variables spaceId postId before limit) decoder
        |> Session.request session
        |> Task.map buildResponse
