module Mutation.PublicizeGroup exposing (Response(..), request, variables)

import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success Group
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation PublicizeGroup(
          $spaceId: ID!,
          $groupId: ID!
        ) {
          publicizeGroup(
            spaceId: $spaceId,
            groupId: $groupId
          ) {
            ...ValidationFields
            group {
              ...GroupFields
            }
          }
        }
        """
        [ Group.fragment
        , ValidationFields.fragment
        ]


variables : Id -> Id -> Encode.Value
variables spaceId groupId =
    Encode.object
        [ ( "spaceId", Id.encoder spaceId )
        , ( "groupId", Id.encoder groupId )
        ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "publicizeGroup", "group" ] Group.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "publicizeGroup", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "publicizeGroup", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Encode.Value -> Session -> Task Session.Error ( Session, Response )
request vars session =
    Session.request session <|
        GraphQL.request document (Just vars) decoder
