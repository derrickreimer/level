module Query.GroupPosts exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership)
import Id exposing (Id)
import InboxStateFilter
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Decode.Pipeline as Pipeline exposing (custom)
import Json.Encode as Encode
import LastActivityFilter
import Post exposing (Post)
import PostStateFilter
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Route.Group exposing (Params(..))
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
        query GroupPosts(
          $spaceSlug: String!,
          $groupName: String!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor,
          $stateFilter: PostStateFilter!,
          $inboxStateFilter: InboxStateFilter!,
          $lastActivityFilter: LastActivityFilter!
        ) {
          group(spaceSlug: $spaceSlug, name: $groupName) {
            posts(
              first: $first,
              last: $last,
              before: $before,
              after: $after,
              filter: {
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
        """
        [ Connection.fragment "PostConnection" Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : Params -> Int -> Maybe Posix -> Maybe Encode.Value
variables params limit maybeAfter =
    let
        filters =
            [ ( "spaceSlug", Encode.string (Route.Group.getSpaceSlug params) )
            , ( "groupName", Encode.string (Route.Group.getGroupName params) )
            , ( "stateFilter", Encode.string (PostStateFilter.toEnum (Route.Group.getState params)) )
            , ( "inboxStateFilter", Encode.string (InboxStateFilter.toEnum (Route.Group.getInboxState params)) )
            , ( "lastActivityFilter", Encode.string (LastActivityFilter.toEnum (Route.Group.getLastActivity params)) )
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
    Decode.at [ "data" ] <|
        (Decode.succeed Data
            |> custom (Decode.at [ "group", "posts" ] (Connection.decoder ResolvedPostWithReplies.decoder))
        )


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
