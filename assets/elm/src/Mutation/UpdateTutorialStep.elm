module Mutation.UpdateTutorialStep exposing (Response(..), request, variables)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)
import ValidationError exposing (ValidationError)
import ValidationFields


type Response
    = Success
    | Invalid (List ValidationError)


document : Document
document =
    GraphQL.toDocument
        """
        mutation UpdateTutorialStep(
          $spaceId: ID!,
          $key: String!,
          $currentStep: Int!
        ) {
          updateTutorialStep(
            spaceId: $spaceId,
            key: $key,
            currentStep: $currentStep
          ) {
            ...ValidationFields
          }
        }
        """
        [ ValidationFields.fragment
        ]


variables : Id -> String -> Int -> Maybe Encode.Value
variables spaceId key currentStep =
    Just <|
        Encode.object
            [ ( "spaceId", Id.encoder spaceId )
            , ( "key", Encode.string key )
            , ( "currentStep", Encode.int currentStep )
            ]


successDecoder : Decoder Response
successDecoder =
    Decode.succeed Success


failureDecoder : Decoder Response
failureDecoder =
    Decode.map Invalid <|
        Decode.at [ "data", "updateTutorialStep", "errors" ] (Decode.list ValidationError.decoder)


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
    Decode.at [ "data", "updateTutorialStep", "success" ] Decode.bool
        |> Decode.andThen conditionalDecoder


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    Session.request session <|
        GraphQL.request document maybeVariables decoder
