module Query.RoomSettings exposing (Params, Response(..), Data, decoder, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Room exposing (Room, roomDecoder)
import GraphQL


type alias Params =
    { id : String
    }


type alias Data =
    { room : Room
    }


type Response
    = Found Data
    | NotFound


query : String
query =
    """
      query GetRoomSettings(
        $id: ID!
      ) {
        viewer {
          room(id: $id) {
            id
            name
            description
            subscriberPolicy
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "id", Encode.string params.id )
        ]


foundDecoder : Decode.Decoder Response
foundDecoder =
    Decode.map Found
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "room" ] roomDecoder)
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
