module Mutation.CreatePost exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Connection exposing (Connection)
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import Data.ValidationFields as ValidationFields
import Data.ValidationError as ValidationError exposing (ValidationError)
import GraphQL exposing (Document)
import Session exposing (Session)


type Response
    = Success Post
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
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
