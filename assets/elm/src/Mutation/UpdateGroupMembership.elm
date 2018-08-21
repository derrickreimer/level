module Mutation.UpdateGroupMembership exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.GroupMembership exposing (GroupMembershipState(..), stateDecoder)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


type Response
    = Success GroupMembershipState
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation UpdateGroupMembership(
          $spaceId: ID!,
          $groupId: ID!,
          $state: GroupMembershipState!
        ) {
          updateGroupMembership(
            spaceId: $spaceId,
            groupId: $groupId,
            state: $state
          ) {
            ...ValidationFields
            membership {
              state
            }
          }
        }
        """
        [ Data.ValidationFields.fragment
        ]


variables : String -> String -> GroupMembershipState -> Maybe Encode.Value
variables spaceId groupId state =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            , ( "state", Data.GroupMembership.stateEncoder state )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.at [ "data", "updateGroupMembership" ] <|
        Decode.map Success <|
            Decode.oneOf
                [ Decode.at [ "membership", "state" ] stateDecoder
                , Decode.succeed NotSubscribed
                ]


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateGroupMembership", "errors" ]
            (Decode.list Data.ValidationError.decoder)


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
        Decode.at [ "data", "updateGroupMembership", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : String -> String -> GroupMembershipState -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId state session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId state) decoder
