module Mutation.CreatePost exposing (Response(..), request, variablesWithGroup, variablesWithoutGroup)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success ResolvedPostWithReplies
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation CreatePost(
          $spaceId: ID!,
          $groupId: ID,
          $body: String!,
          $fileIds: [ID],
          $isUrgent: Boolean!
        ) {
          createPost(
            spaceId: $spaceId,
            groupId: $groupId,
            body: $body,
            fileIds: $fileIds,
            isUrgent: $isUrgent
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


variablesWithoutGroup : Id -> String -> List Id -> Bool -> Maybe Encode.Value
variablesWithoutGroup spaceId body fileIds isUrgent =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "body", Encode.string body )
            , ( "fileIds", Encode.list Id.encoder fileIds )
            , ( "isUrgent", Encode.bool isUrgent )
            ]


variablesWithGroup : Id -> Id -> String -> List Id -> Bool -> Maybe Encode.Value
variablesWithGroup spaceId groupId body fileIds isUrgent =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "groupId", Id.encoder groupId )
            , ( "body", Encode.string body )
            , ( "fileIds", Encode.list Id.encoder fileIds )
            , ( "isUrgent", Encode.bool isUrgent )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "createPost", "post" ] ResolvedPostWithReplies.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "createPost", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "createPost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
