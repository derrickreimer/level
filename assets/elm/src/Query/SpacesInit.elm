module Query.SpacesInit exposing (Response, request)

import Connection exposing (Connection)
import GraphQL exposing (Document, Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Repo exposing (Repo)
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import User exposing (User)


type alias Response =
    { userId : Id
    , spaceIds : Connection Id
    , repo : Repo
    }


type alias Data =
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


decoder : Decoder Data
decoder =
    Decode.at [ "data", "viewer" ] <|
        Decode.map2 Data
            User.decoder
            (Decode.field "spaceUsers" (Connection.decoder (Decode.field "space" Space.decoder)))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setUser data.user
                |> Repo.setSpaces (Connection.toList data.spaces)

        resp =
            Response
                (User.id data.user)
                (Connection.map Space.id data.spaces)
                repo
    in
    ( session, resp )


request : Int -> Session -> Task Session.Error ( Session, Response )
request limit session =
    GraphQL.request (document Root) (variables Root limit) decoder
        |> Session.request session
        |> Task.map buildResponse
