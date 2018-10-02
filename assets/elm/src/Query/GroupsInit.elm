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
    , bookmarkIds : List Id
    , groupIds : Connection Id
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , groups : Connection Group
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
          $after: Cursor
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
              groups(
                first: $first,
                last: $last,
                before: $before,
                after: $after
              ) {
                ...GroupConnectionFields
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
        , Connection.fragment "GroupConnection" Group.fragment
        ]


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        spaceSlug =
            Encode.string (Route.Groups.getSpaceSlug params)

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
                    ]

                ( Nothing, Just after ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", Encode.int limit )
                    , ( "after", Encode.string after )
                    ]

                ( _, _ ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", Encode.int limit )
                    ]
    in
    Just (Encode.object values)


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map4 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "groups" ] (Connection.decoder Group.decoder))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.bookmarks
                |> Repo.setGroups (Connection.toList data.groups)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Connection.map Group.id data.groups)
                repo
    in
    ( session, resp )


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    GraphQL.request (document params) (variables params limit) decoder
        |> Session.request session
        |> Task.map buildResponse
