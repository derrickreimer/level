module Mutation.MarkRoomMessageAsRead exposing (Params, request, variables, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Session exposing (Session)
import GraphQL


type alias Params =
    { roomId : String
    , messageId : String
    }


query : String
query =
    """
      mutation MarkRoomMessageAsRead(
        $roomId: ID!,
        $messageId: ID!
      ) {
        markRoomMessageAsRead(
          roomId: $roomId,
          messageId: $messageId
        ) {
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
        [ ( "roomId", Encode.string params.roomId )
        , ( "messageId", Encode.string params.messageId )
        ]


decoder : Decode.Decoder Bool
decoder =
    Decode.at [ "data", "markRoomMessageAsRead", "success" ] Decode.bool


request : Params -> Session -> Http.Request Bool
request params session =
    GraphQL.request session query (Just (variables params)) decoder
