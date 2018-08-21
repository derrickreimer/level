module Mutation.UpdateSpaceAvatar exposing (Response(..), request)

import Data.Space exposing (Space)
import Data.ValidationError exposing (ValidationError)
import Data.ValidationFields
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)


type Response
    = Success Space
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation UpdateSpaceAvatar(
          $spaceId: ID!,
          $data: String!
        ) {
          updateSpaceAvatar(
            spaceId: $spaceId,
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


variables : String -> String -> Maybe Encode.Value
variables spaceId data =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "data", Encode.string data )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.map Success <|
        Decode.at [ "data", "updateSpaceAvatar", "space" ] Data.Space.decoder


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


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId data session =
    Session.request session <|
        GraphQL.request document (variables spaceId data) decoder
