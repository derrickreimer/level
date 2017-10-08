module Query.Bootstrap exposing (request, Space, Response, RoomSubscriptionConnection)

import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import GraphQL


type alias Space =
    { id : String
    , name : String
    }


type alias RoomSubscriptionConnection =
    { edges : List RoomSubscriptionEdge
    }


type alias RoomSubscriptionEdge =
    { node : RoomSubscription
    }


type alias RoomSubscription =
    { room : Room
    }


type alias Room =
    { id : String
    , name : String
    }


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


spaceDecoder : Decode.Decoder Space
spaceDecoder =
    Pipeline.decode Space
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string


roomSubscriptionConnectionDecoder : Decode.Decoder RoomSubscriptionConnection
roomSubscriptionConnectionDecoder =
    Pipeline.decode RoomSubscriptionConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list roomSubscriptionEdgeDecoder))


roomSubscriptionEdgeDecoder : Decode.Decoder RoomSubscriptionEdge
roomSubscriptionEdgeDecoder =
    Pipeline.decode RoomSubscriptionEdge
        |> Pipeline.custom (Decode.at [ "node" ] roomSubscriptionDecoder)


roomSubscriptionDecoder : Decode.Decoder RoomSubscription
roomSubscriptionDecoder =
    Pipeline.decode RoomSubscription
        |> Pipeline.custom (Decode.at [ "room" ] roomDecoder)


roomDecoder : Decode.Decoder Room
roomDecoder =
    Pipeline.decode Room
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "name" Decode.string


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
