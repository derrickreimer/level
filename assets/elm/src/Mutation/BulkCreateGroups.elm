module Mutation.BulkCreateGroups exposing (Response(..), request)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode
import Data.Group
import Data.ValidationFields
import Session exposing (Session)
import GraphQL exposing (Document)


type Response
    = Success


document : Document
document =
    GraphQL.document
        """
        mutation BulkCreateGroups(
          $spaceId: ID!,
          $names: [String]!
        ) {
          bulkCreateGroups(
            spaceId: $spaceId,
            names: $names
          ) {
            payloads {
              ...ValidationFields
              group {
                ...GroupFields
              }
              args {
                name
              }
            }
          }
        }
        """
        [ Data.Group.fragment
        , Data.ValidationFields.fragment
        ]


variables : String -> List String -> Maybe Encode.Value
variables spaceId names =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "names", Encode.list (List.map Encode.string names) )
            ]


decoder : Decode.Decoder Response
decoder =
    -- For now, we aren't bothering to parse the result here since we don't
    -- expect there to be validation errors with controlled input in the
    -- onboarding phase. If we start allowing user-supplied input, we should
    -- actually decode the result.
    Decode.succeed Success


request : String -> List String -> Session -> Task Session.Error ( Session, Response )
request spaceId names session =
    Session.request session <|
        GraphQL.request document (variables spaceId names) decoder
