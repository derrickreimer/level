module Mutation.ReopenPost exposing (Response(..), request)

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
        mutation ReopenPost(
          $spaceId: ID!,
          $postId: ID!
        ) {
          reopenPost(
            spaceId: $spaceId,
            postId: $postId
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


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "reopenPost", "post" ] Post.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "reopenPost", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "reopenPost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> Id -> Session -> Task Session.Error ( Session, Response )
request spaceId postId session =
    Session.request session <|
        GraphQL.request document (variables spaceId postId) decoder
