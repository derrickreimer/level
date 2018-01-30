module Query.Invitations exposing (Params, Response(..), Data, decoder, request)

import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Invitation exposing (InvitationConnection, invitationConnectionDecoder)
import Data.Session exposing (Session)
import GraphQL


type alias Params =
    { afterCursor : String
    , limit : Int
    }


type alias Data =
    { invitations : InvitationConnection
    }


type Response
    = Found Data


query : String
query =
    """
      query GetInvitations(
        $afterCursor: Cursor
        $limit: Int!
      ) {
        viewer {
          space {
            invitations(first: $limit, after: $afterCursor) {
              edges {
                node {
                  id
                  email
                  insertedAt
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
              }
              totalCount
            }
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "afterCursor", Encode.string params.afterCursor )
        , ( "limit", Encode.int params.limit )
        ]


foundDecoder : Decode.Decoder Response
foundDecoder =
    Decode.map Found
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "invitations" ] invitationConnectionDecoder)
        )


decoder : Decode.Decoder Response
decoder =
    Decode.at [ "data", "viewer", "space" ] foundDecoder


request : Session -> Params -> Http.Request Response
request session params =
    GraphQL.request session query (Just (variables params)) decoder
