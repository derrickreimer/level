module Query.GroupInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Decode.Pipeline as Pipeline exposing (custom)
import Json.Encode as Encode
import NewRepo exposing (NewRepo)
import Post exposing (Post)
import Reply exposing (Reply)
import ResolvedPost exposing (ResolvedPost)
import Route.Group exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : String
    , spaceId : String
    , bookmarkIds : List String
    , groupId : String
    , postWithRepliesIds : Connection ( String, Connection String )
    , featuredMemberIds : List String
    , repo : NewRepo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    , resolvedPosts : Connection ResolvedPost
    , featuredMembers : List SpaceUser
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
              spaceUser {
                ...SpaceUserFields
              }
            }
            posts(
              first: $first,
              last: $last,
              before: $before,
              after: $after,
              filter: { watching: ALL },
              orderBy: { field: LAST_ACTIVITY_AT, direction: DESC }
            ) {
              ...PostConnectionFields
              edges {
                node {
                  replies(last: 3) {
                    ...ReplyConnectionFields
                  }
                }
              }
            }
          }
        }
        """
        [ Group.fragment
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


decoder : Decoder Data
decoder =
    Decode.at [ "data" ] <|
        (Decode.succeed Data
            |> custom (Decode.at [ "spaceUser" ] SpaceUser.decoder)
            |> custom (Decode.at [ "spaceUser", "space" ] Space.decoder)
            |> custom (Decode.at [ "spaceUser", "bookmarks" ] (list Group.decoder))
            |> custom (Decode.at [ "group" ] Group.decoder)
            |> custom (Decode.at [ "group", "posts" ] (Connection.decoder ResolvedPost.decoder))
            |> custom (Decode.at [ "group", "featuredMemberships" ] (list (field "spaceUser" SpaceUser.decoder)))
        )


addPostsToRepo : Connection ResolvedPost -> NewRepo -> NewRepo
addPostsToRepo resolvedPosts repo =
    List.foldr ResolvedPost.addToRepo repo (Connection.toList resolvedPosts)


unresolvePosts : Connection ResolvedPost -> Connection ( String, Connection String )
unresolvePosts resolvedPosts =
    Connection.map ResolvedPost.unresolve resolvedPosts


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            NewRepo.empty
                |> NewRepo.setSpaceUser data.viewer
                |> NewRepo.setSpace data.space
                |> NewRepo.setGroups data.bookmarks
                |> NewRepo.setGroup data.group
                |> addPostsToRepo data.resolvedPosts
                |> NewRepo.setSpaceUsers data.featuredMembers

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Group.id data.group)
                (unresolvePosts data.resolvedPosts)
                (List.map SpaceUser.id data.featuredMembers)
                repo
    in
    ( session, resp )


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    GraphQL.request document (variables params limit) decoder
        |> Session.request session
        |> Task.map buildResponse
