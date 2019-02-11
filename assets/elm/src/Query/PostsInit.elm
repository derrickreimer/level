module Query.PostsInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import InboxStateFilter exposing (InboxStateFilter)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Post exposing (Post)
import PostStateFilter exposing (PostStateFilter)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Route.Posts exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , groupIds : List Id
    , spaceUserIds : List Id
    , bookmarkIds : List Id
    , featuredUserIds : List Id
    , postWithRepliesIds : Connection ( Id, Connection Id )
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    , resolvedPosts : Connection ResolvedPostWithReplies
    }


document : Document
document =
    GraphQL.toDocument
        """
        query PostsInit(
          $spaceSlug: String!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor,
          $followingStateFilter: FollowingStateFilter!,
          $stateFilter: PostStateFilter!,
          $inboxStateFilter: InboxStateFilter!
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
                filter: {
                  followingState: $followingStateFilter,
                  state: $stateFilter,
                  inboxState: $inboxStateFilter
                },
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
        spaceSlug =
            Encode.string (Route.Posts.getSpaceSlug params)

        stateFilter =
            case Route.Posts.getState params of
                PostStateFilter.Open ->
                    Encode.string "OPEN"

                PostStateFilter.Closed ->
                    Encode.string "CLOSED"

                PostStateFilter.All ->
                    Encode.string "ALL"

        ( followingStateFilter, inboxStateFilter ) =
            case Route.Posts.getInboxState params of
                InboxStateFilter.Undismissed ->
                    ( Encode.string "ALL", Encode.string "UNDISMISSED" )

                _ ->
                    ( Encode.string "IS_FOLLOWING", Encode.string "ALL" )

        values =
            case
                ( Route.Posts.getBefore params
                , Route.Posts.getAfter params
                )
            of
                ( Just before, Nothing ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "last", Encode.int 20 )
                    , ( "before", Encode.string before )
                    , ( "stateFilter", stateFilter )
                    , ( "followingStateFilter", followingStateFilter )
                    , ( "inboxStateFilter", inboxStateFilter )
                    ]

                ( Nothing, Just after ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", Encode.int 20 )
                    , ( "after", Encode.string after )
                    , ( "stateFilter", stateFilter )
                    , ( "followingStateFilter", followingStateFilter )
                    , ( "inboxStateFilter", inboxStateFilter )
                    ]

                ( _, _ ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", Encode.int 20 )
                    , ( "stateFilter", stateFilter )
                    , ( "followingStateFilter", followingStateFilter )
                    , ( "inboxStateFilter", inboxStateFilter )
                    ]
    in
    Just (Encode.object values)


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map7 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (Decode.at [ "space", "groups", "edges" ] (list (field "node" Group.decoder)))
            (Decode.at [ "space", "spaceUsers", "edges" ] (list (field "node" SpaceUser.decoder)))
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "featuredUsers" ] (list SpaceUser.decoder))
            (Decode.at [ "space", "posts" ] <| Connection.decoder ResolvedPostWithReplies.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpace data.space
                |> Repo.setGroups data.groups
                |> Repo.setSpaceUsers data.spaceUsers
                |> Repo.setSpaceUser data.viewer
                |> Repo.setGroups data.bookmarks
                |> Repo.setSpaceUsers data.featuredUsers
                |> ResolvedPostWithReplies.addManyToRepo (Connection.toList data.resolvedPosts)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.groups)
                (List.map SpaceUser.id data.spaceUsers)
                (List.map Group.id data.bookmarks)
                (List.map SpaceUser.id data.featuredUsers)
                (Connection.map ResolvedPostWithReplies.unresolve data.resolvedPosts)
                repo
    in
    ( session, resp )


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    GraphQL.request document (variables params) decoder
        |> Session.request session
        |> Task.map buildResponse
