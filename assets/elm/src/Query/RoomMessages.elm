module Query.RoomMessages exposing (Params, Response(..), Data, decoder, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Room exposing (RoomMessageConnection, RoomMessageEdge, roomMessageConnectionDecoder)
import GraphQL


type alias Params =
    { roomId : String
    , afterCursor : String
    , limit : Int
    }


type alias Data =
    { messages : RoomMessageConnection
    }


type Response
    = Found Data
    | NotFound


query : String
query =
    """
      query GetRoomMessages(
        $roomId: ID!
        $afterCursor: Cursor
        $limit: Int
      ) {
        viewer {
          room(id: $roomId) {
            messages(first: $limit, after: $afterCursor) {
              pageInfo {
                hasPreviousPage
                hasNextPage
                startCursor
                endCursor
              }
              edges {
                node {
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
                cursor
              }
            }
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "roomId", Encode.string params.roomId )
        , ( "afterCursor", Encode.string params.afterCursor )
        , ( "limit", Encode.int params.limit )
        ]


foundDecoder : Decode.Decoder Response
foundDecoder =
    Decode.map Found
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "room", "messages" ] roomMessageConnectionDecoder)
        )


notFoundDecoder : Decode.Decoder Response
notFoundDecoder =
    Decode.at [ "room" ] (Decode.null NotFound)


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.oneOf [ foundDecoder, notFoundDecoder ]


request : String -> Params -> Http.Request Response
request apiToken params =
    GraphQL.request apiToken query (Just (variables params)) decoder
