module Query.InboxInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Connection exposing (Connection)
import Component.Mention
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { mentions : Connection Component.Mention.Model
    }


document : Document
document =
    GraphQL.document
        """
        query InboxInit(
          $spaceId: ID!
        ) {
          space(id: $spaceId) {
            mentionedPosts(first: 10) {
              ...PostConnectionFields
            }
          }
        }
        """
        [ Connection.fragment "PostConnection" Component.Mention.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "space", "mentionedPosts" ] <|
        Decode.map Response (Connection.decoder Component.Mention.decoder)


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceId session =
    Session.request session <|
        GraphQL.request document (variables spaceId) decoder
