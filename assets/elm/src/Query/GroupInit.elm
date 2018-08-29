module Query.GroupInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import Route.Group exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    , posts : Connection Component.Post.Model
    , featuredMemberships : List GroupMembership
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GroupInit(
          $spaceSlug: String!,
          $groupId: ID!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
            }
            bookmarks {
              ...GroupFields
            }
          }
          group(id: $groupId) {
            ...GroupFields
            featuredMemberships {
              ...GroupMembershipFields
            }
            posts(
              first: $first,
              last: $last,
              before: $before,
              after: $after,
              orderBy: { field: LAST_ACTIVITY_AT, direction: DESC }
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
        """
        [ Group.fragment
        , GroupMembership.fragment
        , SpaceUser.fragment
        , Space.fragment
        , Connection.fragment "PostConnection" Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        values =
            case params of
                Root spaceSlug id ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "groupId", Encode.string id )
                    , ( "first", Encode.int limit )
                    ]

                After spaceSlug id cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "groupId", Encode.string id )
                    , ( "first", Encode.int limit )
                    , ( "after", Encode.string cursor )
                    ]

                Before spaceSlug id cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "groupId", Encode.string id )
                    , ( "last", Encode.int limit )
                    , ( "before", Encode.string cursor )
                    ]
    in
    Just (Encode.object values)


postComponentsDecoder : Decoder (Connection Component.Post.Model)
postComponentsDecoder =
    Connection.decoder <|
        Component.Post.decoder Component.Post.Feed False


decoder : Decoder Response
decoder =
    Decode.at [ "data" ] <|
        (Decode.succeed Response
            |> Pipeline.custom (Decode.at [ "spaceUser" ] SpaceUser.decoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "space" ] Space.decoder)
            |> Pipeline.custom (Decode.at [ "spaceUser", "bookmarks" ] (Decode.list Group.decoder))
            |> Pipeline.custom (Decode.at [ "group" ] Group.decoder)
            |> Pipeline.custom (Decode.at [ "group", "posts" ] postComponentsDecoder)
            |> Pipeline.custom (Decode.at [ "group", "featuredMemberships" ] (Decode.list GroupMembership.decoder))
        )


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    Session.request session <|
        GraphQL.request document (variables params limit) decoder
