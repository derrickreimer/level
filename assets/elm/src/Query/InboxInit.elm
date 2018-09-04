module Query.InboxInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import Route.Inbox exposing (Params(..))
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
        query InboxInit(
          $spaceSlug: String!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor
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
                first: $first,
                last: $last,
                before: $before,
                after: $after,
                filter: { inbox: UNREAD_OR_READ },
                orderBy: { field: LAST_PINGED_AT, direction: DESC }
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


variables : Params -> Maybe Encode.Value
variables params =
    let
        values =
            case params of
                Root spaceSlug ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "first", Encode.int 20 )
                    ]

                After spaceSlug cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "first", Encode.int 20 )
                    , ( "after", Encode.string cursor )
                    ]

                Before spaceSlug cursor ->
                    [ ( "spaceSlug", Encode.string spaceSlug )
                    , ( "last", Encode.int 20 )
                    , ( "before", Encode.string cursor )
                    ]
    in
    Just (Encode.object values)


decoder : Decoder Response
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map5 Response
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "featuredUsers" ] (list SpaceUser.decoder))
            (Decode.at [ "space", "posts" ] <| Connection.decoder (Component.Post.decoder Component.Post.Feed True))


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    Session.request session <|
        GraphQL.request document (variables params) decoder
