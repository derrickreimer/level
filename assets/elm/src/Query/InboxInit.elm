module Query.InboxInit exposing (Data, request, variables)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Response exposing (Response)
import Route.Inbox exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Data =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , featuredUserIds : List Id
    , postWithRepliesIds : Connection ( Id, Connection Id )
    , repo : Repo
    }


type alias ResolvedData =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    , resolvedPosts : Connection ResolvedPostWithReplies
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
          $after: Cursor,
          $inboxStateFilter: InboxStateFilter!,
          $lastActivityFilter: LastActivityFilter!
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
                  inboxState: $inboxStateFilter,
                  lastActivity: $lastActivityFilter
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


variables : Params -> Encode.Value
variables params =
    let
        spaceSlug =
            Encode.string (Route.Inbox.getSpaceSlug params)

        limit =
            Encode.int 20

        inboxStateFilter =
            castInboxState (Route.Inbox.getState params)

        lastActivityFilter =
            castLastActivity (Route.Inbox.getLastActivity params)

        values =
            case
                ( Route.Inbox.getBefore params
                , Route.Inbox.getAfter params
                )
            of
                ( Just before, Nothing ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "last", limit )
                    , ( "before", Encode.string before )
                    , ( "inboxStateFilter", Encode.string inboxStateFilter )
                    , ( "lastActivityFilter", Encode.string lastActivityFilter )
                    ]

                ( Nothing, Just after ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", limit )
                    , ( "after", Encode.string after )
                    , ( "inboxStateFilter", Encode.string inboxStateFilter )
                    , ( "lastActivityFilter", Encode.string lastActivityFilter )
                    ]

                ( _, _ ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", limit )
                    , ( "inboxStateFilter", Encode.string inboxStateFilter )
                    , ( "lastActivityFilter", Encode.string lastActivityFilter )
                    ]
    in
    Encode.object values


castInboxState : Route.Inbox.State -> String
castInboxState state =
    case state of
        Route.Inbox.Undismissed ->
            "UNDISMISSED"

        Route.Inbox.Dismissed ->
            "DISMISSED"


castLastActivity : Route.Inbox.LastActivity -> String
castLastActivity lastActivity =
    case lastActivity of
        Route.Inbox.All ->
            "ALL"

        Route.Inbox.Today ->
            "TODAY"


decoder : Decoder (Response Data)
decoder =
    let
        resolvedDecoder =
            Decode.at [ "data", "spaceUser" ] <|
                Decode.map5 ResolvedData
                    SpaceUser.decoder
                    (field "space" Space.decoder)
                    (field "bookmarks" (list Group.decoder))
                    (Decode.at [ "space", "featuredUsers" ] (list SpaceUser.decoder))
                    (Decode.at [ "space", "posts" ] <| Connection.decoder ResolvedPostWithReplies.decoder)
    in
    Decode.oneOf
        [ Decode.map Response.Found <|
            Decode.map unresolve resolvedDecoder
        , Decode.succeed Response.NotFound
        ]


unresolve : ResolvedData -> Data
unresolve resolvedData =
    let
        repo =
            Repo.empty
                |> Repo.setSpace resolvedData.space
                |> Repo.setSpaceUser resolvedData.viewer
                |> Repo.setGroups resolvedData.bookmarks
                |> Repo.setSpaceUsers resolvedData.featuredUsers
                |> ResolvedPostWithReplies.addManyToRepo (Connection.toList resolvedData.resolvedPosts)
    in
    Data
        (SpaceUser.id resolvedData.viewer)
        (Space.id resolvedData.space)
        (List.map Group.id resolvedData.bookmarks)
        (List.map SpaceUser.id resolvedData.featuredUsers)
        (Connection.map ResolvedPostWithReplies.unresolve resolvedData.resolvedPosts)
        repo


request : Encode.Value -> Session -> Task Session.Error ( Session, Response Data )
request vars session =
    GraphQL.request document (Just vars) decoder
        |> Session.request session
