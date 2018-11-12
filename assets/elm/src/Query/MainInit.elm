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
import User exposing (User)


type alias Response =
    { currentUser : User
    , spaceIds : List Id
    , spaceUserIds : List Id
    }


document : Document
document =
    GraphQL.toDocument
        """
        query MainInit {
          viewer {
            ...UserFields
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
        [ User.fragment
        ]


variables : Maybe Encode.Value
variables =
    Nothing


decoder : Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map3 Response
            User.decoder
            (Decode.at [ "spaceUsers", "edges" ] (list (Decode.at [ "node", "space", "id" ] Id.decoder)))
            (Decode.at [ "spaceUsers", "edges" ] (list (Decode.at [ "node", "id" ] Id.decoder)))


request : Session -> Task Session.Error ( Session, Response )
request session =
    Session.request session <|
        GraphQL.request document variables decoder
