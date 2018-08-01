module Mutation.CreatePost exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Post exposing (Post)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
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
            }
          }
        }
        """
        [ Data.Post.fragment 0
        , Data.ValidationFields.fragment
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
            Decode.at [ "data", "createPost", "post" ] Data.Post.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "createPost", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "createPost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId body session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId body) decoder
