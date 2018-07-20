module Query.UserSettingsInit exposing (Response, request)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Data.User exposing (User)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { user : User
    }


document : Document
document =
    GraphQL.document
        """
        query UserSettingsInit {
          viewer {
            ...UserFields
          }
        }
        """
        [ Data.User.fragment
        ]


variables : Maybe Encode.Value
variables =
    Nothing


decoder : Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map Response
            Data.User.decoder


request : Session -> Task Session.Error ( Session, Response )
request session =
    Session.request session <|
        GraphQL.request document variables decoder
