module Mutation.DismissMentions exposing (Response(..), request)

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
        mutation DismissMentions(
          $spaceId: ID!,
          $postId: ID!
        ) {
          dismissMentions(
            spaceId: $spaceId,
            postId: $postId
          ) {
            ...ValidationFields
          }
        }
        """
        [ Data.ValidationFields.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceId postId =
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
            Decode.at [ "data", "dismissMentions", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "dismissMentions", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId postId session =
    Session.request session <|
        GraphQL.request document (variables spaceId postId) decoder
