module Mutation.CompleteSetupStep exposing (Params, Response(..), request, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Setup exposing (State, setupStateDecoder, setupStateEncoder)
import Session exposing (Session)
import GraphQL


type alias Params =
    { spaceId : String
    , state : State
    , isSkipped : Bool
    }


type Response
    = Success State


query : String
query =
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


variables : Params -> Encode.Value
variables params =
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
request params session =
    GraphQL.request session query (Just (variables params)) decoder
