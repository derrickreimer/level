module Query.MainInit exposing (Response, request)

import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list, string)
import Json.Encode as Encode
import Repo exposing (Repo)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import User exposing (User)


type alias Response =
    { currentUser : User
    , spaceIds : List Id
    , spaceUserIds : List Id
    , repo : Repo
    }


type alias Data =
    { currentUser : User
    , spaces : List Space
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
                    ...SpaceFields
                  }
                }
              }
            }
          }
        }
        """
        [ User.fragment
        , Space.fragment
        ]


variables : Maybe Encode.Value
variables =
    Nothing


decoder : Decoder Data
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map3 Data
            User.decoder
            (Decode.at [ "spaceUsers", "edges" ] (list (Decode.at [ "node", "space" ] Space.decoder)))
            (Decode.at [ "spaceUsers", "edges" ] (list (Decode.at [ "node", "id" ] Id.decoder)))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaces data.spaces

        resp =
            Response
                data.currentUser
                (List.map Space.id data.spaces)
                data.spaceUserIds
                repo
    in
    ( session, resp )


request : Session -> Task Session.Error ( Session, Response )
request session =
    GraphQL.request document variables decoder
        |> Session.request session
        |> Task.map buildResponse
