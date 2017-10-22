module Query.Room exposing (Params, Response(..), okDecoder, notFoundDecoder, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Room exposing (Room, roomDecoder)
import GraphQL


type alias Params =
    { id : String
    }


type alias OkResponse =
    { room : Room }


type Response
    = Ok OkResponse
    | NotFound


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


okDecoder : Decode.Decoder Response
okDecoder =
    Decode.map Ok
        (Pipeline.decode OkResponse
            |> Pipeline.custom (Decode.at [ "room" ] roomDecoder)
        )


notFoundDecoder : Decode.Decoder Response
notFoundDecoder =
    Decode.at [ "room" ] (Decode.null NotFound)


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        okDecoder


request : String -> Params -> Http.Request Response
request apiToken params =
    GraphQL.request apiToken query (Just (variables params)) decoder
