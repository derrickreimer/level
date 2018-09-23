module Query.MainInit exposing (Response, request)

import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list, string)
import Json.Encode as Encode
import Session exposing (Session)
import Space exposing (Space, setupStateDecoder)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { spaceIds : List Id
    , spaceUserIds : List Id
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
            (list (Decode.at [ "node", "space", "id" ] Id.decoder))
            (list (Decode.at [ "node", "id" ] Id.decoder))


request : Session -> Task Session.Error ( Session, Response )
request session =
    Session.request session <|
        GraphQL.request document variables decoder
