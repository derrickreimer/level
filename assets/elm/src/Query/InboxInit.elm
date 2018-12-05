module Query.InboxInit exposing (Response, request)

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
import Route.Inbox exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , featuredUserIds : List Id
    , postWithRepliesIds : Connection ( Id, Connection Id )
    , repo : Repo
    }


type alias Data =
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
            Encode.string (Route.Inbox.getSpaceSlug params)

        limit =
            Encode.int 20

        inboxStateFilter =
            castFilters (Route.Inbox.getState params)

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
                    ]

                ( Nothing, Just after ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", limit )
                    , ( "after", Encode.string after )
                    , ( "inboxStateFilter", Encode.string inboxStateFilter )
                    ]

                ( _, _ ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "first", limit )
                    , ( "inboxStateFilter", Encode.string inboxStateFilter )
                    ]
    in
    Just (Encode.object values)


castFilters : Route.Inbox.State -> String
castFilters filter =
    case filter of
        Route.Inbox.Undismissed ->
            "UNDISMISSED"

        Route.Inbox.Dismissed ->
            "DISMISSED"


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map5 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (field "bookmarks" (list Group.decoder))
            (Decode.at [ "space", "featuredUsers" ] (list SpaceUser.decoder))
            (Decode.at [ "space", "posts" ] <| Connection.decoder ResolvedPostWithReplies.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpace data.space
                |> Repo.setSpaceUser data.viewer
                |> Repo.setGroups data.bookmarks
                |> Repo.setSpaceUsers data.featuredUsers
                |> ResolvedPostWithReplies.addManyToRepo (Connection.toList data.resolvedPosts)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
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



-- INTERNAL


encodeMaybeStrings : List ( String, Maybe String ) -> List ( String, Encode.Value ) -> List ( String, Encode.Value )
encodeMaybeStrings maybePairs encodeValues =
    let
        reducer ( key, maybeValue ) accum =
            case maybeValue of
                Just value ->
                    ( key, Encode.string value ) :: accum

                Nothing ->
                    accum
    in
    List.foldr reducer encodeValues maybePairs
