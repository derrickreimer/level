module ResolvedPost exposing (ResolvedPost, addToRepo, decoder, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedReply exposing (ResolvedReply)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPost =
    { post : Post
    , resolvedReplies : Connection ResolvedReply
    , author : SpaceUser
    , groups : List Group
    }


decoder : Decoder ResolvedPost
decoder =
    Decode.map4 ResolvedPost
        Post.decoder
        (field "replies" (Connection.decoder ResolvedReply.decoder))
        (field "author" SpaceUser.decoder)
        (field "groups" (list Group.decoder))


addToRepo : ResolvedPost -> Repo -> Repo
addToRepo post repo =
    repo
        |> Repo.setPost post.post
        |> ResolvedReply.addManyToRepo (Connection.toList post.resolvedReplies)
        |> Repo.setSpaceUser post.author
        |> Repo.setGroups post.groups


unresolve : ResolvedPost -> ( Id, Connection Id )
unresolve post =
    ( Post.id post.post
    , Connection.map ResolvedReply.unresolve post.resolvedReplies
    )
