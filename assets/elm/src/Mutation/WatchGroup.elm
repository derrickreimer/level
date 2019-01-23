module Mutation.WatchGroup exposing (Response(..), request)

import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field)
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
        mutation WatchGroup(
          $spaceId: ID!,
          $groupId: ID!,
        ) {
          watchGroup(
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
        [ ValidationFields.fragment
        , Group.fragment
        ]


variables : Id -> Id -> Maybe Encode.Value
variables spaceId groupId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.at [ "data", "watchGroup" ] <|
        Decode.map Success <|
            field "group" Group.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "watchGroup", "errors" ]
            (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "watchGroup", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> Id -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId) decoder
