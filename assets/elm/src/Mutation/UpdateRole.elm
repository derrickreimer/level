module Mutation.UpdateRole exposing (Response(..), request, variables)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success SpaceUser
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation UpdateRole(
          $spaceId: ID!,
          $spaceUserId: ID!,
          $role: SpaceUserRole!
        ) {
          updateRole(
            spaceId: $spaceId,
            spaceUserID: $spaceUserId,
            role: $role
          ) {
            ...ValidationFields
            spaceUser {
              ...SpaceUserFields
            }
          }
        }
        """
        [ ValidationFields.fragment
        , SpaceUser.fragment
        ]


variables : Id -> Id -> SpaceUser.Role -> Maybe Encode.Value
variables spaceId spaceUserId role =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "spaceUserId", Id.encoder spaceUserId )
            , ( "role", SpaceUser.roleEncoder role )
            ]


conditionalDecoder : Bool -> Decoder Response
conditionalDecoder success =
    case success of
        True ->
            Decode.map Success <|
                Decode.at [ "data", "updateRole", "spaceUser" ] SpaceUser.decoder

        False ->
            Decode.map Invalid <|
                Decode.at [ "data", "updateRole", "errors" ] (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    Decode.at [ "data", "updateRole", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
