module Mutation.CreateGroupInvitations exposing (Response(..), request)

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
        mutation CreateGroupInvitations(
          $spaceId: ID!,
          $groupId: ID!,
          $inviteeIds: [ID]!
        ) {
          createGroupInvitations(
            spaceId: $spaceId,
            groupId: $groupId,
            inviteeIds: $inviteeIds
          ) {
            ...ValidationFields
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : Id -> Id -> List Id -> Maybe Encode.Value
variables spaceId groupId inviteeIds =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "groupId", Id.encoder groupId )
            , ( "inviteeIds", Encode.list Id.encoder inviteeIds )
            ]


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "createGroupInvitations", "errors" ]
            (Decode.list ValidationError.decoder)


decoder : Decoder Response
decoder =
    let
        conditionalDecoder : Bool -> Decoder Response
        conditionalDecoder success =
            case success of
                True ->
                    Decode.succeed Success

                False ->
                    failureDecoder
    in
    Decode.at [ "data", "createGroupInvitations", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> Id -> List Id -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId inviteeIds session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId inviteeIds) decoder
