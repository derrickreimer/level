module Query.Posts exposing (Response, request)

import PostView
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import InboxStateFilter exposing (InboxStateFilter)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import LastActivityFilter
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
import Time exposing (Posix)


type alias Response =
    { resolvedPosts : Connection ResolvedPostWithReplies
    , repo : Repo
    }


type alias Data =
    { resolvedPosts : Connection ResolvedPostWithReplies
    }


document : Document
document =
    GraphQL.toDocument
        """
        query Posts(
          $spaceSlug: String!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor,
          $followingStateFilter: FollowingStateFilter!,
          $stateFilter: PostStateFilter!,
          $inboxStateFilter: InboxStateFilter!,
          $lastActivityFilter: LastActivityFilter!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            space {
              posts(
                first: $first,
                last: $last,
                before: $before,
                after: $after,
                filter: {
                  followingState: $followingStateFilter,
                  state: $stateFilter,
                  inboxState: $inboxStateFilter,
                  lastActivity: $lastActivityFilter
                }
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
        [ Connection.fragment "PostConnection" Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : Params -> Int -> Maybe Posix -> Maybe Encode.Value
variables params limit maybeAfter =
    let
        spaceSlug =
            Encode.string (Route.Posts.getSpaceSlug params)

        followingStateFilter =
            case Route.Posts.getInboxState params of
                InboxStateFilter.All ->
                    "IS_FOLLOWING"

                _ ->
                    "ALL"

        filters =
            [ ( "spaceSlug", spaceSlug )
            , ( "stateFilter", Encode.string (PostStateFilter.toEnum (Route.Posts.getState params)) )
            , ( "followingStateFilter", Encode.string followingStateFilter )
            , ( "inboxStateFilter", Encode.string (InboxStateFilter.toEnum (Route.Posts.getInboxState params)) )
            , ( "lastActivityFilter", Encode.string (LastActivityFilter.toEnum (Route.Posts.getLastActivity params)) )
            ]

        cursors =
            case maybeAfter of
                Just after ->
                    [ ( "first", Encode.int limit )
                    , ( "after", Encode.int (Time.posixToMillis after) )
                    ]

                Nothing ->
                    [ ( "first", Encode.int limit )
                    ]
    in
    Just (Encode.object (filters ++ cursors))


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map Data
            (Decode.at [ "space", "posts" ] <| Connection.decoder ResolvedPostWithReplies.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> ResolvedPostWithReplies.addManyToRepo (Connection.toList data.resolvedPosts)

        resp =
            Response
                data.resolvedPosts
                repo
    in
    ( session, resp )


request : Params -> Int -> Maybe Posix -> Session -> Task Session.Error ( Session, Response )
request params limit maybeAfter session =
    GraphQL.request document (variables params limit maybeAfter) decoder
        |> Session.request session
        |> Task.map buildResponse
