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
    , groupIds : List Id
    , spaceUserIds : List Id
    , bookmarkIds : List Id
    , groupId : Id
    , isDefault : Bool
    , isPrivate : Bool
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    , bookmarks : List Group
    , group : Group
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GroupSettingsInit(
          $spaceSlug: String!,
          $groupName: String!
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
          group(spaceSlug: $spaceSlug, name: $groupName) {
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
            , ( "groupName", Encode.string <| Route.GroupSettings.getGroupName params )
            ]
        )


decoder : Decoder Data
decoder =
    Decode.at [ "data" ] <|
        Decode.map6 Data
            (field "spaceUser" SpaceUser.decoder)
            (Decode.at [ "spaceUser", "space" ] Space.decoder)
            (Decode.at [ "spaceUser", "space", "groups", "edges" ] (list (field "node" Group.decoder)))
            (Decode.at [ "spaceUser", "space", "spaceUsers", "edges" ] (list (field "node" SpaceUser.decoder)))
            (Decode.at [ "spaceUser", "bookmarks" ] (list Group.decoder))
            (field "group" Group.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.groups
                |> Repo.setSpaceUsers data.spaceUsers
                |> Repo.setGroup data.group
                |> Repo.setGroups data.bookmarks

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.groups)
                (List.map SpaceUser.id data.spaceUsers)
                (List.map Group.id data.bookmarks)
                (Group.id data.group)
                (Group.isDefault data.group)
                (Group.isPrivate data.group)
                repo
    in
    ( session, resp )


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    GraphQL.request document (variables params) decoder
        |> Session.request session
        |> Task.map buildResponse
