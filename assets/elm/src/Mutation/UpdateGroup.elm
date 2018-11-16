module Mutation.UpdateGroup exposing (Response(..), isDefaultVariables, request, variables)

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
        mutation UpdateGroup(
          $spaceId: ID!,
          $groupId: ID!,
          $name: String,
          $isPrivate: Boolean,
          $isDefault: Boolean
        ) {
          updateGroup(
            spaceId: $spaceId,
            groupId: $groupId,
            name: $name,
            isPrivate: $isPrivate,
            isDefault: $isDefault
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


variables : Id -> Id -> Maybe String -> Maybe Bool -> Encode.Value
variables spaceId groupId maybeName maybeIsPrivate =
    let
        requiredFields =
            [ ( "spaceId", Id.encoder spaceId )
            , ( "groupId", Id.encoder groupId )
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
    Encode.object (requiredFields ++ nameField ++ privacyField)


isDefaultVariables : Id -> Id -> Bool -> Encode.Value
isDefaultVariables spaceId groupId isDefault =
    Encode.object
        [ ( "spaceId", Id.encoder spaceId )
        , ( "groupId", Id.encoder groupId )
        , ( "isDefault", Encode.bool isDefault )
        ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateGroup", "group" ] Group.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateGroup", "errors" ] (Decode.list ValidationError.decoder)


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


request : Encode.Value -> Session -> Task Session.Error ( Session, Response )
request vars session =
    Session.request session <|
        GraphQL.request document (Just vars) decoder
