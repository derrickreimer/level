module Mutation.PostToGroup exposing (Params, Response(..), request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Post exposing (Post)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Params =
    { spaceId : String
    , groupId : String
    , body : String
    }


type Response
    = Success Post
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation PostToGroup(
          $spaceId: ID!,
          $groupId: ID!,
          $body: String!
        ) {
          postToGroup(
            spaceId: $spaceId,
            groupId: $groupId,
            body: $body
          ) {
            success
            post {
              ...PostFields
            }
            errors {
              attribute
              message
            }
          }
        }
        """
        [ Data.Post.fragment
        ]


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "groupId", Encode.string params.groupId )
        , ( "body", Encode.string params.body )
        ]


conditionalDecoder : Bool -> Decode.Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "postToGroup", "post" ] Data.Post.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "postToGroup", "errors" ] (Decode.list errorDecoder)
                |> Decode.map Invalid


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "postToGroup", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder
