module Query.MainInit exposing (Response, request)

import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list, string)
import Json.Encode as Encode
import Repo exposing (Repo)
import ResolvedSpace exposing (ResolvedSpace)
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
    , resolvedSpaces : List ResolvedSpace
    , spaceUsers : List SpaceUser
    }


document : Document
document =
    GraphQL.toDocument
        """
        query MainInit {
          viewer {
            ...UserFields
            spaceUsers(
              first: 1000
            ) {
              edges {
                node {
                  ...SpaceUserFields
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
        , SpaceUser.fragment
        ]


variables : Maybe Encode.Value
variables =
    Nothing


decoder : Decoder Data
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map3 Data
            User.decoder
            (Decode.at [ "spaceUsers", "edges" ] (list (Decode.at [ "node", "space" ] ResolvedSpace.decoder)))
            (Decode.at [ "spaceUsers", "edges" ] (list (Decode.at [ "node" ] SpaceUser.decoder)))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> ResolvedSpace.addManyToRepo data.resolvedSpaces
                |> Repo.setSpaceUsers data.spaceUsers
                |> Repo.setUser data.currentUser

        resp =
            Response
                data.currentUser
                (List.map ResolvedSpace.unresolve data.resolvedSpaces)
                (List.map SpaceUser.id data.spaceUsers)
                repo
    in
    ( session, resp )


request : Session -> Task Session.Error ( Session, Response )
request session =
    GraphQL.request document variables decoder
        |> Session.request session
        |> Task.map buildResponse
