module Mutation.CreateReply exposing (Response(..), request)

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
        mutation CreateReply(
          $spaceId: ID!,
          $postId: ID!,
          $body: String!,
          $fileIds: [ID]
        ) {
          createReply(
            spaceId: $spaceId,
            postId: $postId,
            body: $body,
            fileIds: $fileIds
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


variables : Id -> Id -> String -> List Id -> Maybe Encode.Value
variables spaceId postId body fileIds =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "postId", Id.encoder postId )
            , ( "body", Encode.string body )
            , ( "fileIds", Encode.list Id.encoder fileIds )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "createReply", "reply" ] Reply.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "createReply", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "createReply", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> Id -> String -> List Id -> Session -> Task Session.Error ( Session, Response )
request spaceId postId body fileIds session =
    Session.request session <|
        GraphQL.request document (variables spaceId postId body fileIds) decoder
