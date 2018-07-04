module Mutation.UpdateGroupMembership exposing (Params, Response(..), request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.GroupMembership exposing (GroupMembershipState)
import Data.ValidationError exposing (ValidationError, errorDecoder)
import Session exposing (Session)
import GraphQL exposing (Document)


type alias Params =
    { spaceId : String
    , groupId : String
    , state : GroupMembershipState
    }


type Response
    = Success GroupMembershipState
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
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
            success
            membership {
              state
            }
            errors {
              attribute
              message
            }
          }
        }
        """
        []


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "groupId", Encode.string params.groupId )
        , ( "state", Data.GroupMembership.stateEncoder params.state )
        ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateGroupMembership", "membership", "state" ]
            Data.GroupMembership.stateDecoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateGroupMembership", "errors" ] (Decode.list errorDecoder)


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


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (Just (variables params)) decoder
