module Mutation.UpdateDigestSettings exposing (Response(..), request, variables)

import DigestSettings exposing (DigestSettings)
import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)
import User exposing (User)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success DigestSettings
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation UpdateDigestSettings(
          $spaceId: ID!,
          $isEnabled: Boolean
        ) {
          updateDigestSettings(
            spaceId: $spaceId,
            isEnabled: $isEnabled
          ) {
            ...ValidationFields
            digestSettings {
              ...DigestSettingsFields
            }
          }
        }
        """
        [ User.fragment
        , DigestSettings.fragment
        , ValidationFields.fragment
        ]


variables : Id -> Bool -> Maybe Encode.Value
variables spaceId isEnabled =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "isEnabled", Encode.bool isEnabled )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateDigestSettings", "digestSettings" ] DigestSettings.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateDigestSettings", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "updateDigestSettings", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Id -> Bool -> Session -> Task Session.Error ( Session, Response )
request spaceId isEnabled session =
    Session.request session <|
        GraphQL.request document (variables spaceId isEnabled) decoder
