module Mutation.CreatePost exposing (Response(..), request, variables)

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
          $recipientIds: [ID],
          $body: String!,
          $fileIds: [ID],
          $isUrgent: Boolean!
        ) {
          createPost(
            spaceId: $spaceId,
            groupId: $groupId,
            recipientIds: $recipientIds
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


variables : Id -> Maybe Id -> List Id -> String -> List Id -> Bool -> Maybe Encode.Value
variables spaceId maybeGroupId recipientIds body fileIds isUrgent =
    let
        baseParams =
            [ ( "spaceId", Id.encoder spaceId )
            , ( "recipientIds", Encode.list Id.encoder recipientIds )
            , ( "body", Encode.string body )
            , ( "fileIds", Encode.list Id.encoder fileIds )
            , ( "isUrgent", Encode.bool isUrgent )
            ]

        groupParam =
            case maybeGroupId of
                Just groupId ->
                    [ ( "groupId", Id.encoder groupId )
                    ]

                Nothing ->
                    []
    in
    Just <|
        Encode.object (baseParams ++ groupParam)


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
