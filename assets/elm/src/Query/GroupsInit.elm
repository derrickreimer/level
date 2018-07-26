module Query.GroupsInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { groups : Connection Group
    }


document : Document
document =
    GraphQL.document
        """
        query GroupsInit(
          $spaceId: ID!,
          $after: Cursor,
          $limit: Int!
        ) {
          space(id: $spaceId) {
            groups(first: $limit, after: $after) {
              ...GroupConnectionFields
            }
          }
        }
        """
        [ Connection.fragment "GroupConnection" Group.fragment
        ]


variables : String -> Maybe String -> Int -> Maybe Encode.Value
variables spaceId maybeAfter limit =
    let
        cursor =
            case maybeAfter of
                Just after ->
                    [ ( "after", Encode.string after ) ]

                Nothing ->
                    []
    in
        Just <|
            Encode.object <|
                List.append cursor
                    [ ( "spaceId", Encode.string spaceId )
                    , ( "limit", Encode.int limit )
                    ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "space", "groups" ] <|
        Decode.map Response (Connection.decoder Group.decoder)


request : String -> Maybe String -> Int -> Session -> Task Session.Error ( Session, Response )
request spaceId maybeAfter limit session =
    Session.request session <|
        GraphQL.request document (variables spaceId maybeAfter limit) decoder
