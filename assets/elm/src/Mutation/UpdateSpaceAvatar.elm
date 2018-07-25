module Mutation.UpdateSpaceAvatar exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Space exposing (Space)
import Data.ValidationFields
import Data.ValidationError exposing (ValidationError)
import Session exposing (Session)
import GraphQL exposing (Document)


type Response
    = Success Space
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.document
        """
        mutation UpdateSpaceAvatar(
          $data: String!
        ) {
          updateSpaceAvatar(
            data: $data
          ) {
            ...ValidationFields
            space {
              ...SpaceFields
            }
          }
        }
        """
        [ Data.Space.fragment
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
        Decode.at [ "data", "updateSpaceAvatar", "user" ] Data.Space.decoder


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateSpaceAvatar", "errors" ] (Decode.list Data.ValidationError.decoder)


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
        Decode.at [ "data", "updateSpaceAvatar", "success" ] Decode.bool
            |> Decode.andThen conditionalDecoder


request : String -> Session -> Task Session.Error ( Session, Response )
request data session =
    Session.request session <|
        GraphQL.request document (variables data) decoder
