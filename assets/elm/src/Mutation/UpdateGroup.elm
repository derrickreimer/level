module Mutation.UpdateGroup exposing (Params, Response(..), request, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Group exposing (Group)
import Data.ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


type alias Params =
    { spaceId : String
    , groupId : String
    , name : String
    }


type Response
    = Success Group
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation UpdateGroup(
          $spaceId: ID!,
          $groupId: ID!,
          $name: String!
        ) {
          updateGroup(
            spaceId: $spaceId,
            groupId: $groupId,
            name: $name
          ) {
            success
            group {
              ...GroupFields
            }
            errors {
              attribute
              message
            }
          }
        }
        """
        [ Data.Group.fragment
        ]


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "groupId", Encode.string params.groupId )
        , ( "name", Encode.string params.name )
        ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateGroup", "group" ] Data.Group.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateGroup", "errors" ] (Decode.list Data.ValidationError.decoder)


decoder : Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    successDecoder

                False ->
                    failureDecoder
    in
        Decode.at [ "data", "updateGroup", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder
