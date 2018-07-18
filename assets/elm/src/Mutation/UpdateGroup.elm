module Mutation.UpdateGroup exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Group exposing (Group)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


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
            ...ValidationFields
            group {
              ...GroupFields
            }
          }
        }
        """
        [ Data.Group.fragment
        , Data.ValidationFields.fragment
        ]


variables : String -> String -> String -> Maybe Encode.Value
variables spaceId groupId name =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            , ( "name", Encode.string name )
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


request : String -> String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId name session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId name) decoder
