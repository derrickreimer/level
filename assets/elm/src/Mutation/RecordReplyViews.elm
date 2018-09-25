module Mutation.RecordReplyViews exposing (Response(..), request)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation RecordReplyViews(
          $spaceId: ID!,
          $replyIds: [ID]!
        ) {
          recordReplyViews(
            spaceId: $spaceId,
            replyIds: $replyIds
          ) {
            ...ValidationFields
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : Id -> List Id -> Maybe Encode.Value
variables spaceId replyIds =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "replyIds", Encode.list Id.encoder replyIds )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.succeed Success

        False ->
            Decode.at [ "data", "recordReplyViews", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "recordReplyViews", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> List Id -> Session -> Task Session.Error ( Session, Response )
request spaceId replyIds session =
    GraphQL.request document (variables spaceId replyIds) decoder
        |> Session.request session
