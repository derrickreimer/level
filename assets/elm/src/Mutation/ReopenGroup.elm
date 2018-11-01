module Mutation.ReopenGroup exposing (Response(..), request)

import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Session exposing (Session)
import Task exposing (Task)


type Response
    = Success Group


document : Document
document =
    GraphQL.toDocument
        """
        mutation ReopenGroup(
          $spaceId: ID!,
          $groupId: ID!
        ) {
          reopenGroup(
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
        Decode.at [ "data", "reopenGroup", "group" ]
            Group.decoder


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceId groupId session =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId) decoder
