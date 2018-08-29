module Query.PostsInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    , posts : Connection Component.Post.Model
    }


document : Document
document =
    GraphQL.toDocument
        """
        query PostsInit(
          $spaceSlug: String!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            bookmarks {
              ...GroupFields
            }
            space {
              ...SpaceFields
              featuredUsers {
                ...SpaceUserFields
              }
              posts(
                first: 10,
                orderBy: { field: POSTED_AT, direction: DESC }
              ) {
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
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Connection.fragment "PostConnection" Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> Maybe Encode.Value
variables spaceSlug =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string spaceSlug )
            ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map5 Response
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "featuredUsers" ] (list SpaceUser.decoder))
            (Decode.at [ "space", "posts" ] <| Connection.decoder (Component.Post.decoder Component.Post.Feed True))


request : String -> Session -> Task Session.Error ( Session, Response )
request spaceSlug session =
    Session.request session <|
        GraphQL.request document (variables spaceSlug) decoder
