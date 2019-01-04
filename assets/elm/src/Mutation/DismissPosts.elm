module Mutation.DismissPosts exposing (Response(..), request)

import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Post exposing (Post)
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success (List Post)
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation DismissPosts(
          $spaceId: ID!,
          $postIds: [ID]!
        ) {
          dismissPosts(
            spaceId: $spaceId,
            postIds: $postIds
          ) {
            ...ValidationFields
            posts {
              ...PostFields
            }
          }
        }
        """
        [ ValidationFields.fragment
        , Post.fragment
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
            Decode.map Success <|
                Decode.at [ "data", "dismissPosts", "posts" ] (Decode.list Post.decoder)

        False ->
            Decode.map Invalid <|
                Decode.at [ "data", "dismissPosts", "errors" ] (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    Decode.at [ "data", "dismissPosts", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : String -> List String -> Session -> Task Session.Error ( Session, Response )
request spaceId postIds session =
    Session.request session <|
        GraphQL.request document (variables spaceId postIds) decoder
