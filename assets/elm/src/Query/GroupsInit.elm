module Query.GroupsInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Route.Groups exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , groups : Connection Group
    }


document : Params -> Document
document params =
    GraphQL.toDocument (documentBody params)
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Connection.fragment "GroupConnection" Group.fragment
        ]


documentBody : Params -> String
documentBody params =
    case params of
        Root _ ->
            """
            query GroupsInit(
              $spaceSlug: String!,
              $limit: Int!
            ) {
              spaceUser(spaceSlug: $spaceSlug) {
                ...SpaceUserFields
                space {
                  ...SpaceFields
                  groups(first: $limit) {
                    ...GroupConnectionFields
                  }
                }
                bookmarks {
                  ...GroupFields
                }
              }
            }
            """

        After _ cursor ->
            """
            query GroupsInit(
              $spaceSlug: String!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              spaceUser(spaceSlug: $spaceSlug) {
                ...SpaceUserFields
                space {
                  ...SpaceFields
                  groups(first: $limit, after: $cursor) {
                    ...GroupConnectionFields
                  }
                }
                bookmarks {
                  ...GroupFields
                }
              }
            }
            """

        Before _ cursor ->
            """
            query GroupsInit(
              $spaceSlug: String!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              spaceUser(spaceSlug: $spaceSlug) {
                ...SpaceUserFields
                space {
                  ...SpaceFields
                  groups(last: $limit, before: $cursor) {
                    ...GroupConnectionFields
                  }
                }
                bookmarks {
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
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "groups" ] (Connection.decoder Group.decoder))


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    Session.request session <|
        GraphQL.request (document params) (variables params limit) decoder
