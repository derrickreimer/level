module Mutation.UpdateReply exposing (Response(..), request)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Reply exposing (Reply)
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success Reply
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation UpdateReply(
          $spaceId: ID!,
          $replyId: ID!,
          $body: String!
        ) {
          updateReply(
            spaceId: $spaceId,
            replyId: $replyId,
            body: $body
          ) {
            ...ValidationFields
            reply {
              ...ReplyFields
            }
          }
        }
        """
        [ Reply.fragment
        , ValidationFields.fragment
        ]


variables : Id -> Id -> String -> Maybe Encode.Value
variables spaceId replyId body =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "replyId", Id.encoder replyId )
            , ( "body", Encode.string body )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateReply", "reply" ] Reply.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateReply", "errors" ] (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    successDecoder

                False ->
                    failureDecoder
    in
    Decode.at [ "data", "updateReply", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> Id -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId replyId body session =
    Session.request session <|
        GraphQL.request document (variables spaceId replyId body) decoder
