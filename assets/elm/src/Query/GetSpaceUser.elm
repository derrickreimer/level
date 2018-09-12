module Query.GetSpaceUser exposing (Response(..), request)

import Connection exposing (Connection)
import Globals exposing (Globals)
import GraphQL exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Repo exposing (Repo)
import Session exposing (Session)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type Response
    = Success SpaceUser
    | NotFound


document : Document
document =
    GraphQL.toDocument
        """
        query GetSpaceUser(
          $spaceId: ID!,
          $userId: ID!
        ) {
          spaceUserByUserId(
            spaceId: $spaceId,
            userId: $userId
          ) {
            ...SpaceUserFields
          }
        }
        """
        [ SpaceUser.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceId userId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "userId", Encode.string userId )
            ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "spaceUserByUserId" ] <|
        Decode.oneOf
            [ Decode.map Success SpaceUser.decoder
            , Decode.null NotFound
            ]



-- REQUESTS


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId userId session =
    Session.request session <|
        GraphQL.request document (variables spaceId userId) decoder
