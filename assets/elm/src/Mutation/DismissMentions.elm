module Mutation.DismissMentions exposing (Response(..), request)

import GraphQL exposing (Document)
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
        mutation DismissMentions(
          $spaceId: ID!,
          $postIds: [ID]!
        ) {
          dismissMentions(
            spaceId: $spaceId,
            postIds: $postId
          ) {
            ...ValidationFields
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : String -> List String -> Maybe Encode.Value
variables spaceId postIds =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "postIds", Encode.list Encode.string postIds )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.succeed Success

        False ->
            Decode.at [ "data", "dismissMentions", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "dismissMentions", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> List String -> Session -> Task Session.Error ( Session, Response )
request spaceId postIds session =
    Session.request session <|
        GraphQL.request document (variables spaceId postIds) decoder
