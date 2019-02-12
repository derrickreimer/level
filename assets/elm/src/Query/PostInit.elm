module Query.PostInit exposing (Response, request)

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
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , groupIds : List Id
    , spaceUserIds : List Id
    , postWithRepliesId : ( Id, Connection Id )
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    , resolvedPost : ResolvedPostWithReplies
    }


document : Document
document =
    GraphQL.toDocument
        """
        query PostInit(
          $spaceSlug: String!
          $postId: ID!
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
              post(id: $postId) {
                ...PostFields
                replies(last: 20) {
                  ...ReplyConnectionFields
                }
              }
            }
          }
        }
        """
        [ SpaceUser.fragment
        , Space.fragment
        , Group.fragment
        , Post.fragment
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]


variables : String -> Id -> Maybe Encode.Value
variables spaceSlug postId =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string spaceSlug )
            , ( "postId", Id.encoder postId )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map5 Data
            SpaceUser.decoder
            (field "space" Space.decoder)
            (Decode.at [ "space", "groups", "edges" ] (list (field "node" Group.decoder)))
            (Decode.at [ "space", "spaceUsers", "edges" ] (list (field "node" SpaceUser.decoder)))
            (Decode.at [ "space", "post" ] ResolvedPostWithReplies.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpace data.space
                |> Repo.setGroups data.groups
                |> Repo.setSpaceUsers data.spaceUsers
                |> Repo.setSpaceUser data.viewer
                |> ResolvedPostWithReplies.addToRepo data.resolvedPost

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.groups)
                (List.map SpaceUser.id data.spaceUsers)
                (ResolvedPostWithReplies.unresolve data.resolvedPost)
                repo
    in
    ( session, resp )


request : String -> String -> Session -> Task Session.Error ( Session, Response )
request spaceSlug postId session =
    GraphQL.request document (variables spaceSlug postId) decoder
        |> Session.request session
        |> Task.map buildResponse
