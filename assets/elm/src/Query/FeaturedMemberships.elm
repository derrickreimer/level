module Query.FeaturedMemberships exposing (Response, request)

import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (field, list)
import Json.Encode as Encode
import Repo exposing (Repo)
import Session exposing (Session)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { spaceUserIds : List Id
    , repo : Repo
    }


type alias Data =
    { spaceUsers : List SpaceUser
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GetFeaturedMemberships(
          $groupId: ID!
        ) {
          group(id: $groupId) {
            featuredMemberships {
              spaceUser {
                ...SpaceUserFields
              }
            }
          }
        }
        """
        [ SpaceUser.fragment
        ]


variables : Id -> Maybe Encode.Value
variables groupId =
    Just <|
        Encode.object
            [ ( "groupId", Id.encoder groupId )
            ]


decoder : Decode.Decoder Data
decoder =
    Decode.map Data
        (Decode.at [ "data", "group", "featuredMemberships" ]
            (list (field "spaceUser" SpaceUser.decoder))
        )


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUsers data.spaceUsers

        resp =
            Response
                (List.map SpaceUser.id data.spaceUsers)
                repo
    in
    ( session, resp )


request : Id -> Session -> Task Session.Error ( Session, Response )
request groupId session =
    GraphQL.request document (variables groupId) decoder
        |> Session.request session
        |> Task.map buildResponse
