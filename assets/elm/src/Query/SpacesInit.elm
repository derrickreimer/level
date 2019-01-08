module Query.SpacesInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document, Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Repo exposing (Repo)
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import User exposing (User)


type alias Response =
    { userId : Id
    , spaceIds : List Id
    , repo : Repo
    }


type alias Data =
    { user : User
    , spaces : List Space
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment SpaceUserSpaceFields on SpaceUser {
          space {
            ...SpaceFields
          }
        }
        """
        [ Space.fragment
        ]


document : Document
document =
    GraphQL.toDocument
        """
        query SpacesInit(
          $limit: Int!
        ) {
          viewer {
            ...UserFields
            spaceUsers(
              first: $limit,
              orderBy: {field: SPACE_NAME, direction: ASC}
            ) {
              edges {
                node {
                  space {
                    ...SpaceFields
                  }
                }
              }
            }
          }
        }
        """
        [ Space.fragment
        , User.fragment
        ]


variables : Int -> Maybe Encode.Value
variables limit =
    Just <|
        Encode.object <|
            [ ( "limit", Encode.int limit )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map2 Data
            User.decoder
            (Decode.at [ "spaceUsers", "edges" ] (Decode.list (Decode.at [ "node", "space" ] Space.decoder)))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setUser data.user
                |> Repo.setSpaces data.spaces

        resp =
            Response
                (User.id data.user)
                (List.map Space.id data.spaces)
                repo
    in
    ( session, resp )


request : Int -> Session -> Task Session.Error ( Session, Response )
request limit session =
    GraphQL.request document (variables limit) decoder
        |> Session.request session
        |> Task.map buildResponse
