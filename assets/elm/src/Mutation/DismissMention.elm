module Mutation.DismissMention exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import GraphQL exposing (Document)
import Session exposing (Session)


type Response
    = Success
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation DismissMention(
          $spaceId: ID!,
          $mentionId: ID!
        ) {
          dismissMention(
            spaceId: $spaceId,
            mentionId: $mentionId
          ) {
            ...ValidationFields
          }
        }
        """
        [ Data.ValidationFields.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceId mentionId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "mentionId", Encode.string mentionId )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.succeed Success

        False ->
            Decode.at [ "data", "dismissMention", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "dismissMention", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId mentionId session =
    Session.request session <|
        GraphQL.request document (variables spaceId mentionId) decoder
