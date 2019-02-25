module Query.Replies exposing (Response, request, variables)

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
import Time exposing (Posix)


type alias Response =
    { resolvedReplies : Connection ResolvedReply
    , repo : Repo
    }


type alias Data =
    { resolvedReplies : Connection ResolvedReply
    }


document : Document
document =
    GraphQL.toDocument
        """
        query Replies(
          $spaceId: ID!
          $postId: ID!
          $before: Timestamp!
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


variables : Id -> Id -> Int -> Posix -> Maybe Encode.Value
variables spaceId postId limit before =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "postId", Id.encoder postId )
            , ( "limit", Encode.int limit )
            , ( "before", Encode.int (Time.posixToMillis before) )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "space", "post", "replies" ] <|
        Decode.map Data
            (Connection.decoder ResolvedReply.decoder)


addRepliesToRepo : Connection ResolvedReply -> Repo -> Repo
addRepliesToRepo conn repo =
    ResolvedReply.addManyToRepo (Connection.toList conn) repo


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        resp =
            Response
                data.resolvedReplies
                (addRepliesToRepo data.resolvedReplies Repo.empty)
    in
    ( session, resp )


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    GraphQL.request document maybeVariables decoder
        |> Session.request session
        |> Task.map buildResponse
