module Query.Room exposing (Params, Response, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Room exposing (Room, roomDecoder)
import GraphQL


type alias Params =
    { id : String
    }


type alias Response =
    { room : Room
    }


query : String
query =
    """
      query GetRoom(
        $id: ID!
      ) {
        viewer {
          room(id: $id) {
            id
            name
            description
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "id", Encode.string params.id )
        ]


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        (Pipeline.decode Response
            |> Pipeline.custom (Decode.at [ "room" ] roomDecoder)
        )


request : String -> Params -> Http.Request Response
request apiToken params =
    GraphQL.request apiToken query (Just (variables params)) decoder
