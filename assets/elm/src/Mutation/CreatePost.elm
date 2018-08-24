module Mutation.CreatePost exposing (Response(..), request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
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
        mutation CreatePost(
          $spaceId: ID!,
          $groupId: ID!,
          $body: String!
        ) {
          createPost(
            spaceId: $spaceId,
            groupId: $groupId,
            body: $body
          ) {
            ...ValidationFields
            post {
              ...PostFields
              replies(last: 5) {
                ...ReplyConnectionFields
              }
            }
          }
        }
        """
        [ Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        , ValidationFields.fragment
        ]


variables : String -> String -> String -> Maybe Encode.Value
variables spaceId groupId body =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            , ( "body", Encode.string body )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "createPost", "post" ] Post.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "createPost", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "createPost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId body session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId body) decoder
