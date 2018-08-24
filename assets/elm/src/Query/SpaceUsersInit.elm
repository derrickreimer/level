module Query.SpaceUsersInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Route.SpaceUsers exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewer : SpaceUser
    , space : Space
    , bookmarkedGroups : List Group
    , spaceUsers : Connection SpaceUser
    }


document : Params -> Document
document params =
    GraphQL.toDocument (documentBody params)
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Connection.fragment "SpaceUserConnection" SpaceUser.fragment
        ]


documentBody : Params -> String
documentBody params =
    case params of
        Root _ ->
            """
            query SpaceUsersInit(
              $spaceSlug: ID!,
              $limit: Int!
            ) {
              spaceUser(spaceSlug: $spaceSlug) {
                ...SpaceUserFields
                space {
                  ...SpaceFields
                  spaceUsers(
                    first: $limit,
                    orderBy: { field: LAST_NAME, direction: ASC }
                  ) {
                    ...SpaceUserConnectionFields
                  }
                }
                bookmarkedGroups {
                  ...GroupFields
                }
              }
            }
            """

        After _ _ ->
            """
            query SpaceUsersInit(
              $spaceSlug: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              spaceUser(spaceSlug: $spaceSlug) {
                ...SpaceUserFields
                space {
                  ...SpaceFields
                  spaceUsers(
                    first: $limit,
                    after: $cursor,
                    orderBy: { field: LAST_NAME, direction: ASC }
                  ) {
                    ...SpaceUserConnectionFields
                  }
                }
                bookmarkedGroups {
                  ...GroupFields
                }
              }
            }
            """

        Before _ _ ->
            """
            query SpaceUsersInit(
              $spaceSlug: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              spaceUser(spaceSlug: $spaceSlug) {
                ...SpaceUserFields
                space {
                  ...SpaceFields
                  spaceUsers(
                    last: $limit,
                    before: $cursor,
                    orderBy: { field: LAST_NAME, direction: ASC }
                  ) {
                    ...SpaceUserConnectionFields
                  }
                }
                bookmarkedGroups {
                  ...GroupFields
                }
              }
            }
            """


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        paramVariables =
            case params of
                After spaceSlug cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "cursor", Encode.string cursor )
                    , ( "limit", Encode.int limit )
                    ]

                Before spaceSlug cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "cursor", Encode.string cursor )
                    , ( "limit", Encode.int limit )
                    ]

                Root spaceSlug ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "limit", Encode.int limit )
                    ]
    in
    Just <|
        Encode.object paramVariables


decoder : Decoder Response
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map4 Response
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarkedGroups" (list Group.decoder))
            (Decode.at [ "space", "spaceUsers" ] (Connection.decoder SpaceUser.decoder))


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    Session.request session <|
        GraphQL.request (document params) (variables params limit) decoder
