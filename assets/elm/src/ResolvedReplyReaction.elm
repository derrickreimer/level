module ResolvedReplyReaction exposing (ResolvedReplyReaction, addManyToRepo, addToRepo, decoder, fragment, resolve, unresolve)

import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import Reply exposing (Reply)
import ReplyReaction exposing (ReplyReaction)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import ResolvedReply exposing (ResolvedReply)
import SpaceUser exposing (SpaceUser)


type alias ResolvedReplyReaction =
    { reaction : ReplyReaction
    , spaceUser : SpaceUser
    , resolvedPost : ResolvedPost
    , resolvedReply : ResolvedReply
    }


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment ReplyReactionFields on ReplyReaction {
              spaceUser {
                ...SpaceUserFields
              }
              post {
                ...PostFields
              }
              reply {
                ...ReplyFields
              }
              value
            }
            """
    in
    GraphQL.toFragment queryBody
        [ SpaceUser.fragment
        , Post.fragment
        , Reply.fragment
        ]


decoder : Decoder ResolvedReplyReaction
decoder =
    Decode.map4 ResolvedReplyReaction
        ReplyReaction.decoder
        (field "spaceUser" SpaceUser.decoder)
        (field "post" ResolvedPost.decoder)
        (field "reply" ResolvedReply.decoder)


addToRepo : ResolvedReplyReaction -> Repo -> Repo
addToRepo resolvedReaction repo =
    repo
        |> Repo.setSpaceUser resolvedReaction.spaceUser
        |> ResolvedPost.addToRepo resolvedReaction.resolvedPost
        |> ResolvedReply.addToRepo resolvedReaction.resolvedReply


addManyToRepo : List ResolvedReplyReaction -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts


resolve : Repo -> ReplyReaction -> Maybe ResolvedReplyReaction
resolve repo reaction =
    Maybe.map4 ResolvedReplyReaction
        (Just reaction)
        (Repo.getSpaceUser (ReplyReaction.spaceUserId reaction) repo)
        (ResolvedPost.resolve repo (ReplyReaction.postId reaction))
        (ResolvedReply.resolve repo (ReplyReaction.replyId reaction))


unresolve : ResolvedReplyReaction -> ReplyReaction
unresolve resolvedReaction =
    resolvedReaction.reaction
