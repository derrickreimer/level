module Mutation.UnbookmarkGroup exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Data.Group as Group exposing (Group)
import Session exposing (Session)
import GraphQL exposing (Document)


type Response
    = Success Group


document : Document
document =
    GraphQL.toDocument
        """
        mutation UnbookmarkGroup(
          $spaceId: ID!,
          $groupId: ID!
        ) {
          unbookmarkGroup(
            spaceId: $spaceId,
            groupId: $groupId
          ) {
            group {
              ...GroupFields
            }
          }
        }
        """
        [ Group.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceId groupId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            ]


decoder : Decoder Response
decoder =
    Decode.map Success <|
        Decode.at [ "data", "unbookmarkGroup", "group" ]
            Group.decoder


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId) decoder
