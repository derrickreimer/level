module ResolvedPostReaction exposing (ResolvedPostReaction, addManyToRepo, addToRepo, decoder, fragment, resolve, unresolve)

import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import PostReaction exposing (PostReaction)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPostReaction =
    { reaction : PostReaction
    , spaceUser : SpaceUser
    , resolvedPost : ResolvedPost
    }


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment ResolvedPostReactionFields on PostReaction {
              id
              spaceUser {
                ...SpaceUserFields
              }
              post {
                ...PostFields
              }
              value
            }
            """
    in
    GraphQL.toFragment queryBody
        [ SpaceUser.fragment
        , Post.fragment
        ]


decoder : Decoder ResolvedPostReaction
decoder =
    Decode.map3 ResolvedPostReaction
        PostReaction.decoder
        (field "spaceUser" SpaceUser.decoder)
        (field "post" ResolvedPost.decoder)


addToRepo : ResolvedPostReaction -> Repo -> Repo
addToRepo resolvedReaction repo =
    repo
        |> Repo.setSpaceUser resolvedReaction.spaceUser
        |> ResolvedPost.addToRepo resolvedReaction.resolvedPost


addManyToRepo : List ResolvedPostReaction -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts


resolve : Repo -> PostReaction -> Maybe ResolvedPostReaction
resolve repo reaction =
    Maybe.map3 ResolvedPostReaction
        (Just reaction)
        (Repo.getSpaceUser (PostReaction.spaceUserId reaction) repo)
        (ResolvedPost.resolve repo (PostReaction.postId reaction))


unresolve : ResolvedPostReaction -> PostReaction
unresolve resolvedReaction =
    resolvedReaction.reaction
