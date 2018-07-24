module Mutation.UpdateUserAvatar exposing (Response(..), request)

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
    GraphQL.document
        """
        mutation UpdateUserAvatar(
          $data: String!
        ) {
          updateUserAvatar(
            data: $data
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


variables : String -> Maybe Encode.Value
variables data =
    Just <|
        Encode.object
            [ ( "data", Encode.string data )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateUserAvatar", "user" ] Data.User.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateUserAvatar", "errors" ] (Decode.list Data.ValidationError.decoder)


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
        Decode.at [ "data", "updateUserAvatar", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : String -> Session -> Task Session.Error ( Session, Response )
request data session =
    Session.request session <|
        GraphQL.request document (variables data) decoder
