module Mutation.UpdateUser exposing (Response(..), request, settingsVariables, timeZoneVariables)

import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)
import User exposing (User)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success User
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation UpdateUser(
          $firstName: String,
          $lastName: String,
          $handle: String,
          $email: String,
          $timeZone: String
        ) {
          updateUser(
            firstName: $firstName,
            lastName: $lastName,
            handle: $handle,
            email: $email,
            timeZone: $timeZone
          ) {
            ...ValidationFields
            user {
              ...UserFields
            }
          }
        }
        """
        [ User.fragment
        , ValidationFields.fragment
        ]


settingsVariables : String -> String -> String -> String -> Maybe Encode.Value
settingsVariables firstName lastName handle email =
    Just <|
        Encode.object
            [ ( "firstName", Encode.string firstName )
            , ( "lastName", Encode.string lastName )
            , ( "handle", Encode.string handle )
            , ( "email", Encode.string email )
            ]


timeZoneVariables : String -> Maybe Encode.Value
timeZoneVariables timeZone =
    Just <|
        Encode.object
            [ ( "timeZone", Encode.string timeZone )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateUser", "user" ] User.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateUser", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "updateUser", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
