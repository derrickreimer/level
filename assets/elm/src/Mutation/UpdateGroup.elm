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
          $name: String,
          $isPrivate: Boolean,
        ) {
          updateGroup(
            spaceId: $spaceId,
            groupId: $groupId,
            name: $name,
            isPrivate: $isPrivate
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


variables : String -> String -> Maybe String -> Maybe Bool -> Maybe Encode.Value
variables spaceId groupId maybeName maybeIsPrivate =
    let
        requiredFields =
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            ]

        nameField =
            case maybeName of
                Just name ->
                    [ ( "name", Encode.string name ) ]

                Nothing ->
                    []

        privacyField =
            case maybeIsPrivate of
                Just isPrivate ->
                    [ ( "isPrivate", Encode.bool isPrivate ) ]

                Nothing ->
                    []
    in
        Just <|
            Encode.object (requiredFields ++ nameField ++ privacyField)


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


request : String -> String -> Maybe String -> Maybe Bool -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId maybeName maybeIsPrivate session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId maybeName maybeIsPrivate) decoder
