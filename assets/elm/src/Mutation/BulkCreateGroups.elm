module Mutation.BulkCreateGroups exposing (Params, Response(..), request, decoder)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Session exposing (Session)
import GraphQL


type alias Params =
    { spaceId : String
    , names : List String
    }


type Response
    = Success


query : String
query =
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
            success
            group {
              id
              name
              description
              isPrivate
            }
            errors {
              attribute
              message
            }
            args {
              name
            }
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "spaceId", Encode.string params.spaceId )
        , ( "names", Encode.list (List.map Encode.string params.names) )
        ]


decoder : Decode.Decoder Response
decoder =
    -- For now, we aren't bothering to parse the result here since we don't
    -- expect there to be validation errors with controlled input in the
    -- onboarding phase. If we start allowing user-supplied input, we should
    -- actually decode the result.
    Decode.succeed Success


request : Params -> Session -> Http.Request Response
request params =
    GraphQL.request query (Just (variables params)) decoder
