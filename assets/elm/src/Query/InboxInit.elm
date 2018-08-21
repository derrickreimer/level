module Query.InboxInit exposing (Response, request)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Component.Post
import Connection exposing (Connection)
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { mentionedPosts : Connection Component.Post.Model
    }


document : Document
document =
    GraphQL.toDocument
        """
        query InboxInit(
          $spaceId: ID!
        ) {
          space(id: $spaceId) {
            mentionedPosts(first: 10) {
              ...PostConnectionFields
              edges {
                node {
                  replies(last: 5) {
                    ...ReplyConnectionFields
                  }
                }
              }
            }
          }
        }
        """
        [ Connection.fragment "PostConnection" Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
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
        Decode.map Response (Connection.decoder (Component.Post.decoder Component.Post.Feed True))


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceId session =
    Session.request session <|
        GraphQL.request document (variables spaceId) decoder
