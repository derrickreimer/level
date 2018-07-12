module Mutation.ReplyToPost exposing (Params, Response(..), request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Reply exposing (Reply)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Params =
    { spaceId : String
    , postId : String
    , body : String
    }


type Response
    = Success Reply
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation ReplyToPost(
          $spaceId: ID!,
          $postId: ID!,
          $body: String!
        ) {
          replyToPost(
            spaceId: $spaceId,
            postId: $postId,
            body: $body
          ) {
            ...ValidationFields
            reply {
              ...ReplyFields
            }
          }
        }
        """
        [ Data.Reply.fragment
        , Data.ValidationFields.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string params.spaceId )
            , ( "postId", Encode.string params.postId )
            , ( "body", Encode.string params.body )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "replyToPost", "reply" ] Data.Reply.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "replyToPost", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "replyToPost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (variables params) decoder
