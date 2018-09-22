module Query.InboxInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import NewRepo exposing (NewRepo)
import Post exposing (Post)
import Reply exposing (Reply)
import Route.Inbox exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : String
    , spaceId : String
    , bookmarkIds : List String
    , featuredUserIds : List String
    , postsWithRepliesIds : Connection ( String, Connection String )
    , repo : NewRepo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    , resolvedPosts : Connection ResolvedPost
    }


type alias ResolvedPost =
    { post : Post
    , replies : Connection Reply
    , author : SpaceUser
    , groups : List Group
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


resolvedPostDecoder : Decoder ResolvedPost
resolvedPostDecoder =
    Decode.map4 ResolvedPost
        Post.decoder
        (field "replies" (Connection.decoder Reply.decoder))
        (field "author" SpaceUser.decoder)
        (field "groups" (list Group.decoder))


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map5 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "featuredUsers" ] (list SpaceUser.decoder))
            (Decode.at [ "space", "posts" ] <| Connection.decoder resolvedPostDecoder)


addPostsToRepo : Connection ResolvedPost -> NewRepo -> NewRepo
addPostsToRepo resolvedPosts repo =
    let
        reducer resolvedPost acc =
            acc
                |> NewRepo.setPost resolvedPost.post
                |> NewRepo.setReplies (Connection.toList resolvedPost.replies)
                |> NewRepo.setSpaceUser resolvedPost.author
                |> NewRepo.setGroups resolvedPost.groups
    in
    List.foldr reducer repo (Connection.toList resolvedPosts)


unresolvePosts : Connection ResolvedPost -> Connection ( String, Connection String )
unresolvePosts resolvedPosts =
    let
        mapper resolvedPost =
            ( Post.id resolvedPost.post
            , Connection.map Reply.id resolvedPost.replies
            )
    in
    Connection.map mapper resolvedPosts


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            NewRepo.empty
                |> NewRepo.setSpace data.space
                |> NewRepo.setSpaceUser data.viewer
                |> NewRepo.setGroups data.bookmarks
                |> NewRepo.setSpaceUsers data.featuredUsers
                |> addPostsToRepo data.resolvedPosts

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (List.map SpaceUser.id data.featuredUsers)
                (unresolvePosts data.resolvedPosts)
                repo
    in
    ( session, resp )


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    GraphQL.request document (variables params) decoder
        |> Session.request session
        |> Task.map buildResponse
