module Query.NewSpaceInit exposing (Response, request)

import Data.User as User exposing (User)
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)


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
