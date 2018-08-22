module Mutation.CreateReply exposing (Response(..), request)

import Data.Reply exposing (Reply)
import Data.ValidationError exposing (ValidationError)
import Data.ValidationFields
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)


type Response
    = Success Reply
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation CreateReply(
          $spaceId: ID!,
          $postId: ID!,
          $body: String!
        ) {
          createReply(
            spaceId: $spaceId,
            postId: $postId,
            body: $body
          ) {
            ...ValidationFields
            reply {
              ...ReplyFields
            }
          }
        }
        """
        [ Data.Reply.fragment
        , Data.ValidationFields.fragment
        ]


variables : String -> String -> String -> Maybe Encode.Value
variables spaceId postId body =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "postId", Encode.string postId )
            , ( "body", Encode.string body )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "createReply", "reply" ] Data.Reply.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "createReply", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "createReply", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId postId body session =
    Session.request session <|
        GraphQL.request document (variables spaceId postId body) decoder
