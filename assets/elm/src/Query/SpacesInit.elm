module Query.SpacesInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Space as Space exposing (Space)
import Data.User as User exposing (User)
import GraphQL exposing (Document, Fragment)
import Session exposing (Session)


type alias Response =
    { user : User
    , spaces : Connection Space
    }


{-| TODO: replace with actual route params
-}
type Params
    = Root
    | After String
    | Before String


fragment : Fragment
fragment =
    GraphQL.toFragment
        """
        fragment SpaceUserSpaceFields on SpaceUser {
          space {
            ...SpaceFields
          }
        }
        """
        [ Space.fragment
        ]


document : Params -> Document
document params =
    GraphQL.toDocument (documentBody params)
        [ Connection.fragment "SpaceUserConnection" fragment
        , User.fragment
        ]


documentBody : Params -> String
documentBody params =
    case params of
        Root ->
            """
            query SpacesInit(
              $limit: Int!
            ) {
              viewer {
                ...UserFields
                spaceUsers(
                  first: $limit,
                  orderBy: {field: SPACE_NAME, direction: ASC}
                ) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """

        After cursor ->
            """
            query SpacesInit(
              $cursor: Cursor!,
              $limit: Int!
            ) {
              viewer {
                ...UserFields
                spaceUsers(
                  first: $limit,
                  after: $cursor,
                  orderBy: {field: SPACE_NAME, direction: ASC}
                ) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """

        Before cursor ->
            """
            query SpacesInit(
              $cursor: Cursor!,
              $limit: Int!
            ) {
              viewer {
                ...UserFields
                spaceUsers(
                  last: $limit,
                  before: $cursor,
                  orderBy: {field: SPACE_NAME, direction: ASC}
                ) {
                  ...SpaceUserConnectionFields
                }
              }
            }
            """


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        paramVariables =
            case params of
                After cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Before cursor ->
                    [ ( "cursor", Encode.string cursor ) ]

                Root ->
                    []
    in
        Just <|
            Encode.object <|
                List.append paramVariables
                    [ ( "limit", Encode.int limit )
                    ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map2 Response
            (User.decoder)
            (Decode.field "spaceUsers" (Connection.decoder (Decode.field "space" Space.decoder)))


request : Int -> Session -> Task Session.Error ( Session, Response )
request limit session =
    let
        -- TODO: Accept this as an argument instead
        params =
            Root
    in
        Session.request session <|
            GraphQL.request (document params) (variables params limit) decoder
