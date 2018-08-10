module Query.InboxInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Mention as Mention exposing (Mention)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { mentions : Connection Mention
    }


document : Document
document =
    GraphQL.document
        """
        query InboxInit(
          $spaceId: ID!
        ) {
          space(id: $spaceId) {
            mentions(first: 10) {
              ...MentionConnectionFields
            }
          }
        }
        """
        [ Connection.fragment "MentionConnection" Mention.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "space", "mentions" ] <|
        Decode.map Response (Connection.decoder Mention.decoder)


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceId session =
    Session.request session <|
        GraphQL.request document (variables spaceId) decoder
