module Mutation.UpdatePost exposing (Response(..), request)

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
        mutation UpdatePost(
          $spaceId: ID!,
          $postId: ID!,
          $body: String!
        ) {
          updatePost(
            spaceId: $spaceId,
            postId: $postId,
            body: $body
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


variables : Id -> Id -> String -> Maybe Encode.Value
variables spaceId postId body =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "postId", Id.encoder postId )
            , ( "body", Encode.string body )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updatePost", "post" ] Post.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updatePost", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "updatePost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> Id -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId postId body session =
    Session.request session <|
        GraphQL.request document (variables spaceId postId body) decoder
