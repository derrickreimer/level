module Query.GroupSettingsInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Repo exposing (Repo)
import Route.GroupSettings exposing (Params)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , groupId : Id
    , spaceUserIds : Connection Id
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    , spaceUsers : Connection SpaceUser
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GroupSettingsInit(
          $spaceSlug: ID!,
          $groupId: ID!
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
          group(id: $groupId) {
            ...GroupFields
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
            [ ( "spaceSlug", Encode.string <| Route.GroupSettings.getSpaceSlug params )
            , ( "groupId", Id.encoder <| Route.GroupSettings.getGroupId params )
            ]
        )


decoder : Decoder Data
decoder =
    Decode.at [ "data" ] <|
        Decode.map5 Data
            (field "spaceUser" SpaceUser.decoder)
            (Decode.at [ "spaceUser", "space" ] Space.decoder)
            (Decode.at [ "spaceUser", "bookmarks" ] (list Group.decoder))
            (field "group" Group.decoder)
            (Decode.at [ "spaceUser", "space", "spaceUsers" ] (Connection.decoder SpaceUser.decoder))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroup data.group
                |> Repo.setGroups data.bookmarks
                |> Repo.setSpaceUsers (Connection.toList data.spaceUsers)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Group.id data.group)
                (Connection.map SpaceUser.id data.spaceUsers)
                repo
    in
    ( session, resp )


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    GraphQL.request document (variables params) decoder
        |> Session.request session
        |> Task.map buildResponse
