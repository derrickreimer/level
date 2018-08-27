module Query.MainInit exposing (Response, request)

import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list, string)
import Json.Encode as Encode
import Session exposing (Session)
import Space exposing (Space, setupStateDecoder)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { spaceIds : List String
    , spaceUserIds : List String
    }


document : Document
document =
    GraphQL.toDocument
        """
        query MainInit {
          viewer {
            spaceUsers(
              first: 100
            ) {
              edges {
                node {
                  id
                  space {
                    id
                  }
                }
              }
            }
          }
        }
        """
        []


variables : Maybe Encode.Value
variables =
    Nothing


decoder : Decoder Response
decoder =
    Decode.at [ "data", "viewer", "spaceUsers", "edges" ] <|
        Decode.map2 Response
            (list (Decode.at [ "node", "space", "id" ] string))
            (list (Decode.at [ "node", "id" ] string))


request : Session -> Task Session.Error ( Session, Response )
request session =
    Session.request session <|
        GraphQL.request document variables decoder
