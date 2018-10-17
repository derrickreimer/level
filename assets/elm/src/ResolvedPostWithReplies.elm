module ResolvedPostWithReplies exposing (ResolvedPostWithReplies, addManyToRepo, addToRepo, decoder, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedReply exposing (ResolvedReply)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPostWithReplies =
    { post : Post
    , author : SpaceUser
    , groups : List Group
    , resolvedReplies : Connection ResolvedReply
    }


decoder : Decoder ResolvedPostWithReplies
decoder =
    Decode.map4 ResolvedPostWithReplies
        Post.decoder
        (field "author" SpaceUser.decoder)
        (field "groups" (list Group.decoder))
        (field "replies" (Connection.decoder ResolvedReply.decoder))


addToRepo : ResolvedPostWithReplies -> Repo -> Repo
addToRepo post repo =
    repo
        |> Repo.setPost post.post
        |> Repo.setSpaceUser post.author
        |> Repo.setGroups post.groups
        |> ResolvedReply.addManyToRepo (Connection.toList post.resolvedReplies)


addManyToRepo : List ResolvedPostWithReplies -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts


resolve : Repo -> ( Id, Connection Id ) -> Maybe ResolvedPostWithReplies
resolve repo ( postId, replyIds ) =
    let
        maybePost =
            Repo.getPost postId repo
    in
    case maybePost of
        Just post ->
            Maybe.map4 ResolvedPostWithReplies
                (Just post)
                (Repo.getSpaceUser (Post.authorId post) repo)
                (Just <| List.filterMap (\id -> Repo.getGroup id repo) (Post.groupIds post))
                (Just <| Connection.filterMap (ResolvedReply.resolve repo) replyIds)

        Nothing ->
            Nothing


unresolve : ResolvedPostWithReplies -> ( Id, Connection Id )
unresolve post =
    ( Post.id post.post
    , Connection.map ResolvedReply.unresolve post.resolvedReplies
    )
