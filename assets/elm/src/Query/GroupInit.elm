module Query.GroupInit exposing (Response, request)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Task exposing (Task)
import Component.Post
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import Data.GroupMembership as GroupMembership exposing (GroupMembership)
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Response =
    { group : Group
    , posts : Connection Component.Post.Model
    , featuredMemberships : List GroupMembership
    , now : Date
    }


document : Document
document =
    GraphQL.document
        """
        query GroupInit(
          $groupId: ID!
        ) {
          group(id: $groupId) {
            ...GroupFields
            featuredMemberships {
              ...GroupMembershipFields
            }
            posts(first: 20) {
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
        [ Group.fragment
        , GroupMembership.fragment
        , Connection.fragment "PostConnection" Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> Maybe Encode.Value
variables groupId =
    Just <|
        Encode.object
            [ ( "groupId", Encode.string groupId )
            ]


postComponentsDecoder : Decoder (Connection Component.Post.Model)
postComponentsDecoder =
    Component.Post.Feed
        |> Component.Post.decoder
        |> Connection.decoder


decoder : Date -> Decoder Response
decoder now =
    Decode.at [ "data", "group" ] <|
        (Pipeline.decode Response
            |> Pipeline.custom Group.decoder
            |> Pipeline.custom (Decode.at [ "posts" ] postComponentsDecoder)
            |> Pipeline.custom (Decode.at [ "featuredMemberships" ] (Decode.list GroupMembership.decoder))
            |> Pipeline.custom (Decode.succeed now)
        )


request : String -> Session -> Date -> Task Session.Error ( Session, Response )
request groupId session now =
    Session.request session <|
        GraphQL.request document (variables groupId) (decoder now)
