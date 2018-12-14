module Mutation.DeleteReplyReaction exposing (Response(..), request, variables)

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
        mutation DeleteReplyReaction(
          $spaceId: ID!,
          $postId: ID!,
          $replyId: ID!
        ) {
          deleteReplyReaction(
            spaceId: $spaceId,
            postId: $postId,
            replyId: $replyId
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


variables : Id -> Id -> Id -> Maybe Encode.Value
variables spaceId postId replyId =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "postId", Id.encoder postId )
            , ( "replyId", Id.encoder replyId )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "deleteReplyReaction", "reply" ] Reply.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "deleteReplyReaction", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "deleteReplyReaction", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
