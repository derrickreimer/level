module Mutation.DeleteReply exposing (Response(..), request, variables)

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
        mutation DeleteReply(
          $spaceId: ID!,
          $replyId: ID!
        ) {
          deleteReply(
            spaceId: $spaceId,
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


variables : Id -> Id -> Maybe Encode.Value
variables spaceId replyId =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "replyId", Id.encoder replyId )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "deleteReply", "reply" ] Reply.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "deleteReply", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "deleteReply", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
