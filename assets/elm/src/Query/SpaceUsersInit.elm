module Query.SpaceUsersInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import NewRepo exposing (NewRepo)
import Route.SpaceUsers exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , spaceUserIds : Connection Id
    , repo : NewRepo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , spaceUsers : Connection SpaceUser
    }


document : Params -> Document
document params =
    GraphQL.toDocument
        """
        query SpaceUsersInit(
          $spaceSlug: ID!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
              spaceUsers(
                first: $first,
                last: $last,
                before: $before,
                after: $after,
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


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        values =
            case params of
                Root spaceSlug ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "first", Encode.int limit )
                    ]

                After spaceSlug cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "after", Encode.string cursor )
                    , ( "first", Encode.int limit )
                    ]

                Before spaceSlug cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "before", Encode.string cursor )
                    , ( "last", Encode.int limit )
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
            (Decode.at [ "space", "spaceUsers" ] (Connection.decoder SpaceUser.decoder))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            NewRepo.empty
                |> NewRepo.setSpaceUser data.viewer
                |> NewRepo.setSpace data.space
                |> NewRepo.setGroups data.bookmarks
                |> NewRepo.setSpaceUsers (Connection.toList data.spaceUsers)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Connection.map SpaceUser.id data.spaceUsers)
                repo
    in
    ( session, resp )


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    GraphQL.request (document params) (variables params limit) decoder
        |> Session.request session
        |> Task.map buildResponse
