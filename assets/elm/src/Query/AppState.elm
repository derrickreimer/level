module Query.AppState exposing (request, Response)

import Data.Room exposing (RoomSubscriptionConnection, roomSubscriptionConnectionDecoder)
import Data.Space exposing (Space, spaceDecoder)
import Data.User exposing (User, userDecoder)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import GraphQL


type alias Response =
    { user : User
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
                  description
                  subscriberPolicy
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
            |> Pipeline.custom userDecoder
            |> Pipeline.custom (Decode.at [ "space" ] spaceDecoder)
            |> Pipeline.custom (Decode.at [ "roomSubscriptions" ] roomSubscriptionConnectionDecoder)
        )


request : String -> Http.Request Response
request apiToken =
    GraphQL.request apiToken query Nothing decoder
