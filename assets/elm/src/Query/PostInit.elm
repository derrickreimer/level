module Query.PostInit exposing (Response, request)

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
    , bookmarkedGroups : List Group
    , post : Component.Post.Model
    }


document : Document
document =
    GraphQL.toDocument
        """
        query PostInit(
          $spaceSlug: String!
          $postId: ID!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            bookmarkedGroups {
              ...GroupFields
            }
            space {
              ...SpaceFields
              post(id: $postId) {
                ...PostFields
                replies(last: 20) {
                  ...ReplyConnectionFields
                }
              }
            }
          }
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceSlug postId =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string spaceSlug )
            , ( "postId", Encode.string postId )
            ]


decoder : Decoder Response
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map4 Response
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarkedGroups" (list Group.decoder))
            (Decode.at [ "space", "post" ] (Component.Post.decoder Component.Post.FullPage True))


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceSlug postId session =
    Session.request session <|
        GraphQL.request document (variables spaceSlug postId) decoder
