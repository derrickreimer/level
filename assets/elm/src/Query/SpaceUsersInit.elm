module Query.SpaceUsersInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Route.SpaceUsers exposing (Params(..))
import Session exposing (Session)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { spaceUsers : Connection SpaceUser
    }


document : Params -> Document
document params =
    GraphQL.toDocument (documentBody params)
        [ Connection.fragment "SpaceUserConnection" SpaceUser.fragment
        ]


documentBody : Params -> String
documentBody params =
    case params of
        Root _ ->
            """
            query SpaceUsersInit(
              $spaceId: ID!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                spaceUsers(
                  first: $limit,
                  orderBy: { field: LAST_NAME, direction: ASC }
                ) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """

        After _ _ ->
            """
            query SpaceUsersInit(
              $spaceId: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                spaceUsers(
                  first: $limit,
                  after: $cursor,
                  orderBy: { field: LAST_NAME, direction: ASC }
                ) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """

        Before _ _ ->
            """
            query SpaceUsersInit(
              $spaceId: ID!,
              $cursor: Cursor!,
              $limit: Int!
            ) {
              space(id: $spaceId) {
                spaceUsers(
                  last: $limit,
                  before: $cursor,
                  orderBy: { field: LAST_NAME, direction: ASC }
                ) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """


variables : String -> Params -> Int -> Maybe Encode.Value
variables spaceId params limit =
    let
        paramVariables =
            case params of
                After _ cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Before _ cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Root _ ->
                    []
    in
    Just <|
        Encode.object <|
            List.append paramVariables
                [ ( "spaceId", Encode.string spaceId )
                , ( "limit", Encode.int limit )
                ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "space", "spaceUsers" ] <|
        Decode.map Response (Connection.decoder SpaceUser.decoder)


request : String -> Params -> Int -> Session -> Task Session.Error ( Session, Response )
request spaceId params limit session =
    Session.request session <|
        GraphQL.request (document params) (variables spaceId params limit) decoder
