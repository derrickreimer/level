module Mutation.RevokeSpaceAccess exposing (Response(..), request, variables)

import GraphQL exposing (Document)
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
        mutation RevokeSpaceAccess(
          $spaceId: ID!,
          $spaceUserId: ID!
        ) {
          revokeSpaceAccess(
            spaceId: $spaceId,
            spaceUserID: $spaceUserId
          ) {
            ...ValidationFields
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : Id -> Id -> Maybe Encode.Value
variables spaceId spaceUserId =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "spaceUserId", Id.encoder spaceUserId )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.succeed Success

        False ->
            Decode.at [ "data", "revokeSpaceAccess", "errors" ] (Decode.list ValidationError.decoder)
                |> Decode.map Invalid


decoder : Decoder Response
decoder =
    Decode.at [ "data", "revokeSpaceAccess", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
