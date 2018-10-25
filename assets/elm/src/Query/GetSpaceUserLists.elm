module Query.GetSpaceUserLists exposing (Response, request)

import Connection exposing (Connection)
import Dict exposing (Dict)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list, string)
import Json.Encode as Encode
import Repo exposing (Repo)
import Session exposing (Session)
import Space exposing (Space, setupStateDecoder)
import SpaceUser exposing (SpaceUser)
import SpaceUserLists exposing (SpaceUserLists)
import Task exposing (Task)


type alias Response =
    { spaceUserLists : SpaceUserLists
    , repo : Repo
    }


type alias Data =
    Dict Id (List SpaceUser)


document : Document
document =
    GraphQL.toDocument
        """
        query SpaceUserLists {
          viewer {
            spaceUsers(
              first: 100
            ) {
              edges {
                node {
                  space {
                    id
                    spaceUsers(
                      first: 1000
                    ) {
                      ...SpaceUserConnectionFields
                    }
                  }
                }
              }
            }
          }
        }
        """
        [ Connection.fragment "SpaceUserConnection" SpaceUser.fragment
        ]


variables : Maybe Encode.Value
variables =
    Nothing


decoder : Decoder Data
decoder =
    Decode.map Dict.fromList <|
        Decode.at [ "data", "viewer", "spaceUsers", "edges" ] (list (field "node" spaceDecoder))


spaceDecoder : Decoder ( Id, List SpaceUser )
spaceDecoder =
    field "space" <|
        Decode.map2 Tuple.pair
            (field "id" Id.decoder)
            (Decode.at [ "spaceUsers", "edges" ] (list (field "node" SpaceUser.decoder)))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        reducer list repo =
            Repo.setSpaceUsers list repo

        spaceUserLists =
            data
                |> Dict.map (\_ list -> List.map SpaceUser.id list)
                |> Dict.foldr SpaceUserLists.setList SpaceUserLists.init

        resp =
            Response
                spaceUserLists
                (List.foldr reducer Repo.empty (Dict.values data))
    in
    ( session, resp )


request : Session -> Task Session.Error ( Session, Response )
request session =
    GraphQL.request document variables decoder
        |> Session.request session
        |> Task.map buildResponse
