module Mutation.UpdateUser exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.User exposing (User)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


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
          $email: String
        ) {
          updateUser(
            firstName: $firstName,
            lastName: $lastName,
            handle: $handle,
            email: $email
          ) {
            ...ValidationFields
            user {
              ...UserFields
            }
          }
        }
        """
        [ Data.User.fragment
        , Data.ValidationFields.fragment
        ]


variables : String -> String -> String -> String -> Maybe Encode.Value
variables firstName lastName handle email =
    Just <|
        Encode.object
            [ ( "firstName", Encode.string firstName )
            , ( "lastName", Encode.string lastName )
            , ( "handle", Encode.string handle )
            , ( "email", Encode.string email )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateUser", "user" ] Data.User.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateUser", "errors" ] (Decode.list Data.ValidationError.decoder)


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


request : String -> String -> String -> String -> Session -> Task Session.Error ( Session, Response )
request firstName lastName handle email session =
    Session.request session <|
        GraphQL.request document (variables firstName lastName handle email) decoder
