module Mutation.CreateRoomMessage exposing (Params, request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Room exposing (Room)
import GraphQL


type alias Params =
    { room : Room
    , body : String
    }


query : String
query =
    """
      mutation CreateRoomMessage(
        $roomId: ID!,
        $body: String!
      ) {
        createRoomMessage(
          roomId: $roomId,
          body: $body
        ) {
          roomMessage {
            body
          }
          success
          errors {
            attribute
            message
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "roomId", Encode.string params.room.id )
        , ( "body", Encode.string params.body )
        ]


decoder : Decode.Decoder Bool
decoder =
    Decode.at [ "data", "createRoomMessage", "success" ] Decode.bool


request : String -> Params -> Http.Request Bool
request apiToken params =
    GraphQL.request apiToken query (Just (variables params)) decoder
