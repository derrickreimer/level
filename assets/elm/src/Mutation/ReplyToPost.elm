module Mutation.ReplyToPost exposing (Params, Response(..), request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Reply exposing (Reply, replyDecoder)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import GraphQL
import Session exposing (Session)


type alias Params =
    { spaceId : String
    , postId : String
    , body : String
    }


type Response
    = Success Reply
    | Invalid (List ValidationError)


query : String
query =
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
          success
          reply {
            id
            body
            bodyHtml
            postedAt
            author {
              id
              firstName
              lastName
              role
            }
          }
          errors {
            attribute
            message
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "postId", Encode.string params.postId )
        , ( "body", Encode.string params.body )
        ]


conditionalDecoder : Bool -> Decode.Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "replyToPost", "reply" ] replyDecoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "replyToPost", "errors" ] (Decode.list errorDecoder)
                |> Decode.map Invalid


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "replyToPost", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request [ query ] (Just (variables params)) decoder
