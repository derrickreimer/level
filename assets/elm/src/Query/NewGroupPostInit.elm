module Query.NewGroupPostInit exposing (Response, request)

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
import Route.NewGroupPost exposing (Params(..))
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , groupId : Id
    , featuredMemberIds : List Id
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    , featuredMembers : List SpaceUser
    }


document : Document
document =
    GraphQL.toDocument
        """
        query GroupInit(
          $spaceSlug: String!,
          $groupId: ID!
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
          }
        }
        """
        [ Group.fragment
        , SpaceUser.fragment
        , Space.fragment
        ]


variables : Params -> Int -> Maybe Encode.Value
variables params limit =
    let
        spaceSlug =
            Encode.string (Route.NewGroupPost.getSpaceSlug params)

        groupId =
            Id.encoder (Route.NewGroupPost.getGroupId params)
    in
    Just
        (Encode.object
            [ ( "spaceSlug", spaceSlug )
            , ( "groupId", groupId )
            ]
        )


decoder : Decoder Data
decoder =
    Decode.at [ "data" ] <|
        (Decode.succeed Data
            |> custom (Decode.at [ "spaceUser" ] SpaceUser.decoder)
            |> custom (Decode.at [ "spaceUser", "space" ] Space.decoder)
            |> custom (Decode.at [ "spaceUser", "bookmarks" ] (list Group.decoder))
            |> custom (Decode.at [ "group" ] Group.decoder)
            |> custom (Decode.at [ "group", "featuredMemberships" ] (list (field "spaceUser" SpaceUser.decoder)))
        )


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.bookmarks
                |> Repo.setGroup data.group
                |> Repo.setSpaceUsers data.featuredMembers

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Group.id data.group)
                (List.map SpaceUser.id data.featuredMembers)
                repo
    in
    ( session, resp )


request : Params -> Int -> Session -> Task Session.Error ( Session, Response )
request params limit session =
    GraphQL.request document (variables params limit) decoder
        |> Session.request session
        |> Task.map buildResponse
