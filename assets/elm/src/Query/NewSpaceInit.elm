module Query.NewSpaceInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Data.User as User exposing (User)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { user : User
    }


document : Document
document =
    GraphQL.toDocument
        """
        query NewSpaceInit {
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
