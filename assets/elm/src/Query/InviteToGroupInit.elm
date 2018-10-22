module Query.InviteToGroupInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Repo exposing (Repo)
import Route.InviteToGroup exposing (Params)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , spaceUserIds : Connection Id
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , spaceUsers : Connection SpaceUser
    }


document : Document
document =
    GraphQL.toDocument
        """
        query InviteToGroupInit(
          $spaceSlug: ID!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
              spaceUsers(
                first: 100,
                orderBy: { field: LAST_NAME, direction: ASC }
              ) {
                ...SpaceUserConnectionFields
              }
            }
            bookmarks {
              ...GroupFields
            }
          }
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Connection.fragment "SpaceUserConnection" SpaceUser.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just
        (Encode.object
            [ ( "spaceSlug", Encode.string <| Route.InviteToGroup.getSpaceSlug params )
            ]
        )


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map4 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "spaceUsers" ] (Connection.decoder SpaceUser.decoder))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.bookmarks
                |> Repo.setSpaceUsers (Connection.toList data.spaceUsers)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Connection.map SpaceUser.id data.spaceUsers)
                repo
    in
    ( session, resp )


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    GraphQL.request document (variables params) decoder
        |> Session.request session
        |> Task.map buildResponse
