module Mutation.DeletePostReaction exposing (Response(..), request, variables)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Post exposing (Post)
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success Post
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation DeletePostReaction(
          $spaceId: ID!,
          $postId: ID!
        ) {
          deletePostReaction(
            spaceId: $spaceId,
            postId: $postId,
            value: "👍"
          ) {
            ...ValidationFields
            post {
              ...PostFields
            }
          }
        }
        """
        [ Post.fragment
        , ValidationFields.fragment
        ]


variables : Id -> Id -> Maybe Encode.Value
variables spaceId postId =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "postId", Id.encoder postId )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "deletePostReaction", "post" ] Post.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "deletePostReaction", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "deletePostReaction", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
