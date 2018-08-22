module Mutation.CompleteSetupStep exposing (Response(..), request)

import GraphQL exposing (Document)
import Json.Decode as Decode
import Json.Encode as Encode
import Session exposing (Session)
import Setup exposing (State, setupStateDecoder, setupStateEncoder)
import Task exposing (Task)


type Response
    = Success State


document : Document
document =
    GraphQL.toDocument
        """
        mutation CompleteSetupStep(
          $spaceId: ID!,
          $state: SpaceSetupState!,
          $isSkipped: Boolean!
        ) {
          completeSetupStep(
            spaceId: $spaceId,
            state: $state,
            isSkipped: $isSkipped
          ) {
            state
          }
        }
        """
        []


variables : String -> State -> Bool -> Maybe Encode.Value
variables spaceId state isSkipped =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "state", setupStateEncoder state )
            , ( "isSkipped", Encode.bool isSkipped )
            ]


decoder : Decode.Decoder Response
decoder =
    Decode.map Success <|
        Decode.at [ "data", "completeSetupStep", "state" ] setupStateDecoder


request : String -> State -> Bool -> Session -> Task Session.Error ( Session, Response )
request spaceId state isSkipped session =
    Session.request session <|
        GraphQL.request document (variables spaceId state isSkipped) decoder
