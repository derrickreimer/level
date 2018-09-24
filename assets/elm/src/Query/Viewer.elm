module Query.Viewer exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import NewRepo exposing (NewRepo)
import Session exposing (Session)
import Task exposing (Task)
import User exposing (User)


type alias Response =
    { viewerId : Id
    , viewer : User
    , repo : NewRepo
    }


type alias Data =
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


decoder : Decoder Data
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map Data User.decoder


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            NewRepo.empty
                |> NewRepo.setUser data.viewer

        resp =
            Response
                (User.id data.viewer)
                data.viewer
                repo
    in
    ( session, resp )


request : Session -> Task Session.Error ( Session, Response )
request session =
    GraphQL.request document variables decoder
        |> Session.request session
        |> Task.map buildResponse
