module Mutation.CompleteSetupStep exposing (Params, Response(..), request, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Setup exposing (State, setupStateDecoder, setupStateEncoder)
import Session exposing (Session)
import GraphQL exposing (Document)


type alias Params =
    { spaceId : String
    , state : State
    , isSkipped : Bool
    }


type Response
    = Success State


document : Document
document =
    GraphQL.document
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


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string params.spaceId )
            , ( "state", setupStateEncoder params.state )
            , ( "isSkipped", Encode.bool params.isSkipped )
            ]


decoder : Decode.Decoder Response
decoder =
    Decode.map Success <|
        Decode.at [ "data", "completeSetupStep", "state" ] setupStateDecoder


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request document (variables params) decoder
