module Mutation.PostToGroup exposing (Params, Response(..), request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Post exposing (Post)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
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
            ...ValidationFields
            post {
              ...PostFields
            }
          }
        }
        """
        [ Data.Post.fragment
        , Data.ValidationFields.fragment
        ]


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "groupId", Encode.string params.groupId )
        , ( "body", Encode.string params.body )
        ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.at [ "data", "postToGroup", "post" ] Data.Post.decoder
                |> Decode.map Success

        False ->
            Decode.at [ "data", "postToGroup", "errors" ] (Decode.list Data.ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "postToGroup", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder
