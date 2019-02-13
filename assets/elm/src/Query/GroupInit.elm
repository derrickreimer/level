module Query.GroupInit exposing (Response, request)

import Component.Post
import Connection exposing (Connection)
import GraphQL exposing (Document)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Decode.Pipeline as Pipeline exposing (custom)
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import Route.Group exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , groupIds : List Id
    , spaceUserIds : List Id
    , groupId : Id
    , featuredMemberIds : List Id
    , postWithRepliesIds : Connection ( Id, Connection Id )
    , isWatching : Bool
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    , group : Group
    , resolvedPosts : Connection ResolvedPostWithReplies
    , featuredMembers : List SpaceUser
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GroupInit(
          $spaceSlug: String!,
          $groupName: String!,
          $first: Int,
          $last: Int,
          $before: Cursor,
          $after: Cursor,
          $stateFilter: PostStateFilter!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
            }
          }
          group(spaceSlug: $spaceSlug, name: $groupName) {
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
              filter: {
                state: $stateFilter
              },
              orderBy: {
                field: LAST_ACTIVITY_AT,
                direction: DESC
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
        [ Group.fragment
        , SpaceUser.fragment
        , Space.fragment
        , Connection.fragment "PostConnection" Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        spaceSlug =
            Encode.string (Route.Group.getSpaceSlug params)

        groupName =
            Encode.string (Route.Group.getGroupName params)

        stateFilter =
            Encode.string (castState <| Route.Group.getState params)

        values =
            case
                ( Route.Group.getBefore params
                , Route.Group.getAfter params
                )
            of
                ( Just before, Nothing ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "groupName", groupName )
                    , ( "last", Encode.int limit )
                    , ( "before", Encode.string before )
                    , ( "stateFilter", stateFilter )
                    ]

                ( Nothing, Just after ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "groupName", groupName )
                    , ( "first", Encode.int limit )
                    , ( "after", Encode.string after )
                    , ( "stateFilter", stateFilter )
                    ]

                ( _, _ ) ->
                    [ ( "spaceSlug", spaceSlug )
                    , ( "groupName", groupName )
                    , ( "first", Encode.int limit )
                    , ( "stateFilter", stateFilter )
                    ]
    in
    Just (Encode.object values)


castState : Route.Group.State -> String
castState state =
    case state of
        Route.Group.Open ->
            "OPEN"

        Route.Group.Closed ->
            "CLOSED"


decoder : Decoder Data
decoder =
    Decode.at [ "data" ] <|
        (Decode.succeed Data
            |> custom (Decode.at [ "spaceUser" ] SpaceUser.decoder)
            |> custom (Decode.at [ "spaceUser", "space" ] Space.decoder)
            |> custom (Decode.at [ "spaceUser", "space", "groups", "edges" ] (list (field "node" Group.decoder)))
            |> custom (Decode.at [ "spaceUser", "space", "spaceUsers", "edges" ] (list (field "node" SpaceUser.decoder)))
            |> custom (Decode.at [ "group" ] Group.decoder)
            |> custom (Decode.at [ "group", "posts" ] (Connection.decoder ResolvedPostWithReplies.decoder))
            |> custom (Decode.at [ "group", "featuredMemberships" ] (list (field "spaceUser" SpaceUser.decoder)))
        )


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.groups
                |> Repo.setSpaceUsers data.spaceUsers
                |> Repo.setGroup data.group
                |> Repo.setSpaceUsers data.featuredMembers
                |> ResolvedPostWithReplies.addManyToRepo (Connection.toList data.resolvedPosts)

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.groups)
                (List.map SpaceUser.id data.spaceUsers)
                (Group.id data.group)
                (List.map SpaceUser.id data.featuredMembers)
                (Connection.map ResolvedPostWithReplies.unresolve data.resolvedPosts)
                (Group.membershipState data.group == GroupMembership.Watching)
                repo
    in
    ( session, resp )


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    GraphQL.request document (variables params limit) decoder
        |> Session.request session
        |> Task.map buildResponse
