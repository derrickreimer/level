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
          $spaceId: ID!
          $groupId: ID!
        ) {
          space(id: $spaceId) {
            group(id: $groupId) {
              ...GroupFields
              featuredMemberships {
                ...GroupMembershipFields
              }
              posts(first: 20) {
                ...PostConnectionFields
              }
            }
          }
        }
        """
        [ Group.fragment
        , GroupMembership.fragment
        , Connection.fragment "PostConnection" (Post.fragment 5)
        ]


variables : String -> String -> Maybe Encode.Value
variables spaceId groupId =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string spaceId )
            , ( "groupId", Encode.string groupId )
            ]


postComponentsDecoder : Decoder (Connection Component.Post.Model)
postComponentsDecoder =
    Component.Post.Feed
        |> Component.Post.decoder
        |> Connection.decoder


decoder : Date -> Decoder Response
decoder now =
    Decode.at [ "data", "space", "group" ] <|
        (Pipeline.decode Response
            |> Pipeline.custom Group.decoder
            |> Pipeline.custom (Decode.at [ "posts" ] postComponentsDecoder)
            |> Pipeline.custom (Decode.at [ "featuredMemberships" ] (Decode.list GroupMembership.decoder))
            |> Pipeline.custom (Decode.succeed now)
        )


request : String -> String -> Session -> Date -> Task Session.Error ( Session, Response )
request spaceId groupId session now =
    Session.request session <|
        GraphQL.request document (variables spaceId groupId) (decoder now)
