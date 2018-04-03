module Query.AppState exposing (request, Response)

import Data.Room exposing (RoomSubscriptionConnection, roomSubscriptionConnectionDecoder)
import Session exposing (Session)
import Data.Space exposing (Space, spaceDecoder)
import Data.User exposing (User, UserConnection, userDecoder, userConnectionDecoder)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import GraphQL


type alias Response =
    { user : User
    , space : Space
    , roomSubscriptions : RoomSubscriptionConnection
    , users : UserConnection
    }


query : String
query =
    """
      {
        viewer {
          id
          firstName
          lastName
          space {
            id
            name
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
          }
          roomSubscriptions(first: 10) {
            edges {
              node {
                room {
                  id
                  name
                  description
                  subscriberPolicy
                  lastMessage {
                    id
                  }
                }
                lastReadMessage {
                  id
                }
                lastReadMessageAt
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
            |> Pipeline.custom (Decode.at [ "space", "users" ] userConnectionDecoder)
        )


request : Session -> Http.Request Response
request session =
    GraphQL.request session query Nothing decoder
