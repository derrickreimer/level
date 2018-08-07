module Mutation.RecordPostView exposing (Response(..), request)

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
        mutation RecordPostView(
          $spaceId: ID!,
          $postId: ID!,
          $lastViewedReplyId: ID
        ) {
          recordPostView(
            spaceId: $spaceId,
            postId: $postId,
            lastViewedReplyId: $lastViewedReplyId
          ) {
            ...ValidationFields
          }
        }
        """
        [ Data.ValidationFields.fragment
        ]


variables : String -> String -> Maybe String -> Maybe Encode.Value
variables spaceId postId maybeReplyId =
    case maybeReplyId of
        Just replyId ->
            Just <|
                Encode.object
                    [ ( "spaceId", Encode.string spaceId )
                    , ( "postId", Encode.string postId )
                    , ( "lastViewedReplyId", Encode.string replyId )
                    ]

        Nothing ->
            Just <|
                Encode.object
                    [ ( "spaceId", Encode.string spaceId )
                    , ( "postId", Encode.string postId )
                    ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.succeed Success

        False ->
            Decode.at [ "data", "recordPostView", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "recordPostView", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> Maybe String -> Session -> Task Session.Error ( Session, Response )
request spaceId postId maybeReplyId session =
    Session.request session <|
        GraphQL.request document (variables spaceId postId maybeReplyId) decoder
