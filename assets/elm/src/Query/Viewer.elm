module Query.Viewer exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)
import User exposing (User)


type alias Response =
    { viewer : User
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GetViewer {
          viewer {
            ...UserFields
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
        Decode.map Response User.decoder


request : Session -> Task Session.Error ( Session, Response )
request session =
    Session.request session <|
        GraphQL.request document variables decoder
