module Query.GroupsInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Repo exposing (Repo)
import Route.Groups exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , groupIds : List Id
    , spaceUserIds : List Id
    , filteredGroups : Connection Group
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    , filteredGroups : Connection Group
    }


document : Params -> Document
document params =
    GraphQL.toDocument
        """
        query GroupsInit(
          $spaceSlug: String!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor,
          $state: GroupStateFilter
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
              filteredGroups: groups(
                first: $first,
                last: $last,
                before: $before,
                after: $after,
                state: $state
              ) {
                ...GroupConnectionFields
              }
            }
          }
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Connection.fragment "GroupConnection" Group.fragment
        ]


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        spaceSlug =
            Encode.string (Route.Groups.getSpaceSlug params)

        state =
            case Route.Groups.getState params of
                Route.Groups.Open ->
                    "OPEN"

                Route.Groups.Closed ->
                    "CLOSED"

        values =
            case
                ( Route.Groups.getBefore params
                , Route.Groups.getAfter params
                )
            of
                ( Just before, Nothing ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "last", Encode.int limit )
                    , ( "before", Encode.string before )
                    , ( "state", Encode.string state )
                    ]

                ( Nothing, Just after ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", Encode.int limit )
                    , ( "after", Encode.string after )
                    , ( "state", Encode.string state )
                    ]

                ( _, _ ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", Encode.int limit )
                    , ( "state", Encode.string state )
                    ]
    in
    Just (Encode.object values)


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map5 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (Decode.at [ "space", "groups", "edges" ] (list (field "node" Group.decoder)))
            (Decode.at [ "space", "spaceUsers", "edges" ] (list (field "node" SpaceUser.decoder)))
            (Decode.at [ "space", "filteredGroups" ] (Connection.decoder Group.decoder))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.groups
                |> Repo.setSpaceUsers data.spaceUsers
                |> Repo.setGroups (Connection.toList data.filteredGroups)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.groups)
                (List.map SpaceUser.id data.spaceUsers)
                data.filteredGroups
                repo
    in
    ( session, resp )


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    GraphQL.request (document params) (variables params limit) decoder
        |> Session.request session
        |> Task.map buildResponse
