module Mutation.CreatePost exposing (Response(..), request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Id exposing (Id)
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
          $body: String!,
          $uploadIds: [ID]
        ) {
          createPost(
            spaceId: $spaceId,
            groupId: $groupId,
            body: $body,
            uploadIds: $uploadIds
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


variables : Id -> Id -> String -> List Id -> Maybe Encode.Value
variables spaceId groupId body uploadIds =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "groupId", Id.encoder groupId )
            , ( "body", Encode.string body )
            , ( "uploadIds", Encode.list Id.encoder uploadIds )
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


request : Id -> Id -> String -> List Id -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId body uploadIds session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId body uploadIds) decoder
