module Query.Room exposing (Params, Response(..), Data, decoder, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Room exposing (Room, RoomMessageConnection, RoomMessageEdge, roomDecoder, roomMessageConnectionDecoder)
import Data.Session exposing (Session)
import Data.User exposing (UserConnection, userConnectionDecoder)
import GraphQL


type alias Params =
    { id : String
    }


type alias Data =
    { room : Room
    , messages : RoomMessageConnection
    , users : UserConnection
    }


type Response
    = Found Data
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
            subscriberPolicy
            users(first: 10) {
              pageInfo {
                hasPreviousPage
                hasNextPage
                startCursor
                endCursor
              }
              edges {
                node {
                  id
                  firstName
                  lastName
                }
                cursor
              }
            }
            messages(first: 20) {
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
        [ ( "id", Encode.string params.id )
        ]


foundDecoder : Decode.Decoder Response
foundDecoder =
    Decode.map Found
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "room" ] roomDecoder)
            |> Pipeline.custom (Decode.at [ "room", "messages" ] roomMessageConnectionDecoder)
            |> Pipeline.custom (Decode.at [ "room", "users" ] userConnectionDecoder)
        )


notFoundDecoder : Decode.Decoder Response
notFoundDecoder =
    Decode.at [ "room" ] (Decode.null NotFound)


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.oneOf [ foundDecoder, notFoundDecoder ]


request : Session -> Params -> Http.Request Response
request session params =
    GraphQL.request session query (Just (variables params)) decoder
