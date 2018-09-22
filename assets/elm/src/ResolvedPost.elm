module ResolvedPost exposing (ResolvedPost, addToRepo, decoder, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Json.Decode as Decode exposing (Decoder, field, list)
import NewRepo exposing (NewRepo)
import Post exposing (Post)
import Reply exposing (Reply)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPost =
    { post : Post
    , replies : Connection Reply
    , author : SpaceUser
    , groups : List Group
    }


decoder : Decoder ResolvedPost
decoder =
    Decode.map4 ResolvedPost
        Post.decoder
        (field "replies" (Connection.decoder Reply.decoder))
        (field "author" SpaceUser.decoder)
        (field "groups" (list Group.decoder))


addToRepo : ResolvedPost -> NewRepo -> NewRepo
addToRepo post repo =
    repo
        |> NewRepo.setPost post.post
        |> NewRepo.setReplies (Connection.toList post.replies)
        |> NewRepo.setSpaceUser post.author
        |> NewRepo.setGroups post.groups


unresolve : ResolvedPost -> ( String, Connection String )
unresolve post =
    ( Post.id post.post
    , Connection.map Reply.id post.replies
    )
