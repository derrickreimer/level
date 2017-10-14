module Query.Bootstrap exposing (request, Response)

import Data.Room exposing (RoomSubscriptionConnection, roomSubscriptionConnectionDecoder)
import Data.Space exposing (Space, spaceDecoder)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import GraphQL


type alias Response =
    { id : String
    , firstName : String
    , lastName : String
    , space : Space
    , roomSubscriptions : RoomSubscriptionConnection
    }


query : String
query =
    """
      {
        viewer {
          id
          username
          firstName
          lastName
          space {
            id
            name
          }
          roomSubscriptions(first: 10) {
            edges {
              node {
                room {
                  id
                  name
                }
              }
            }
          }
        }
      }
    """


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        (Pipeline.decode Response
            |> Pipeline.required "id" Decode.string
            |> Pipeline.required "firstName" Decode.string
            |> Pipeline.required "lastName" Decode.string
            |> Pipeline.custom (Decode.at [ "space" ] spaceDecoder)
            |> Pipeline.custom (Decode.at [ "roomSubscriptions" ] roomSubscriptionConnectionDecoder)
        )


request : String -> Http.Request Response
request apiToken =
    GraphQL.request apiToken query Nothing decoder
