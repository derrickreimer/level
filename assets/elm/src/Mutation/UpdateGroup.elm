module Mutation.UpdateGroup exposing (Params, Response(..), request, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Group exposing (Group, groupDecoder)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import Session exposing (Session)
import GraphQL


type alias Params =
    { spaceId : String
    , groupId : String
    , name : String
    }


type Response
    = Success Group
    | Invalid (List ValidationError)


query : String
query =
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
            id
            name
            description
            isPrivate
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
        , ( "groupId", Encode.string params.groupId )
        , ( "name", Encode.string params.name )
        ]


successDecoder : Decode.Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateGroup", "group" ] groupDecoder


failureDecoder : Decode.Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateGroup", "errors" ] (Decode.list errorDecoder)


decoder : Decode.Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decode.Decoder Response
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
    GraphQL.request query (Just (variables params)) decoder
