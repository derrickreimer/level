module Subscription.LastReadRoomMessageUpdated exposing (Params, Result, operation, variables, decoder)

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
    , messageId : String
    }


operation : String
operation =
    """
      subscription LastReadRoomMessageUpdated(
        $userId: ID!
      ) {
        lastReadRoomMessageUpdated(userId: $userId) {
          roomSubscription {
            room {
              id
            }
            lastReadMessage {
              id
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
    Decode.at [ "data", "lastReadRoomMessageUpdated" ] <|
        (Pipeline.decode Result
            |> Pipeline.custom (Decode.at [ "roomSubscription", "room", "id" ] Decode.string)
            |> Pipeline.custom (Decode.at [ "roomSubscription", "lastReadMessage", "id" ] Decode.string)
        )
