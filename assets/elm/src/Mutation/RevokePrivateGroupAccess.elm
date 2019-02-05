module Mutation.RevokePrivateGroupAccess exposing (Response(..), request, variables)

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
    = Success
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation RevokePrivateGroupAccess(
          $spaceId: ID!,
          $groupId: ID!,
          $spaceUserId: ID!
        ) {
          revokePrivateGroupAccess(
            spaceId: $spaceId,
            groupId: $groupId,
            spaceUserId: $spaceUserId
          ) {
            ...ValidationFields
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : Id -> Id -> Id -> Encode.Value
variables spaceId groupId spaceUserId =
    Encode.object
        [ ( "spaceId", Id.encoder spaceId )
        , ( "groupId", Id.encoder groupId )
        , ( "spaceUserId", Id.encoder spaceUserId )
        ]


successDecoder : Decoder Response
successDecoder =
    Decode.succeed Success


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "revokePrivateGroupAccess", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "revokePrivateGroupAccess", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Encode.Value -> Session -> Task Session.Error ( Session, Response )
request vars session =
    Session.request session <|
        GraphQL.request document (Just vars) decoder
