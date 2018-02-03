module Mutation.CreateRoomMessage exposing (Params, request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Room exposing (Room, RoomMessage, roomMessageDecoder)
import Session exposing (Session)
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
            id
            body
            insertedAt
            insertedAtTs
            user {
              id
              firstName
              lastName
            }
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


successDecoder : Decode.Decoder RoomMessage
successDecoder =
    Decode.at [ "roomMessage" ] roomMessageDecoder



-- TODO: Handle unsuccessful case


decoder : Decode.Decoder RoomMessage
decoder =
    Decode.at [ "data", "createRoomMessage" ] successDecoder


request : Params -> Session -> Http.Request RoomMessage
request params session =
    GraphQL.request session query (Just (variables params)) decoder
