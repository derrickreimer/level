module Subscription.RoomMessageCreated exposing (Params, Result, operation, variables, decoder)

import Data.User exposing (User)
import Data.Room exposing (RoomMessage, roomMessageDecoder)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


type alias Params =
    { user : User
    }


type alias Result =
    { roomId : String
    , roomMessage : RoomMessage
    }


operation : String
operation =
    """
      subscription RoomMessageCreated(
        $userId: ID!
      ) {
        roomMessageCreated(userId: $userId) {
          room {
            id
          }
          roomMessage {
            id
            body
            insertedAtTs
            user {
              id
              firstName
              lastName
            }
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "userId", Encode.string params.user.id )
        ]


decoder : Decode.Decoder Result
decoder =
    Decode.at [ "data", "createRoomMessage" ] <|
        (Pipeline.decode Result
            |> Pipeline.custom (Decode.at [ "room", "id" ] Decode.string)
            |> Pipeline.required "roomMessage" roomMessageDecoder
        )
