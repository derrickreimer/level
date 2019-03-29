module ResolvedPost exposing (ResolvedPost, addManyToRepo, addToRepo, decoder, resolve, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import PostReaction exposing (PostReaction)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedAuthor exposing (ResolvedAuthor)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPost =
    { post : Post
    , author : ResolvedAuthor
    , groups : List Group
    , recipients : List SpaceUser
    , reactions : List PostReaction
    }


decoder : Decoder ResolvedPost
decoder =
    Decode.map5 ResolvedPost
        Post.decoder
        (field "author" ResolvedAuthor.decoder)
        (field "groups" (list Group.decoder))
        (field "recipients" (list SpaceUser.decoder))
        (Decode.at [ "reactions", "edges" ] (list <| field "node" PostReaction.decoder))


addToRepo : ResolvedPost -> Repo -> Repo
addToRepo post repo =
    repo
        |> Repo.setPost post.post
        |> ResolvedAuthor.addToRepo post.author
        |> Repo.setGroups post.groups
        |> Repo.setSpaceUsers post.recipients
        |> Repo.setPostReactions post.reactions


addManyToRepo : List ResolvedPost -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts


resolve : Repo -> Id -> Maybe ResolvedPost
resolve repo postId =
    case Repo.getPost postId repo of
        Just post ->
            Maybe.map5 ResolvedPost
                (Just post)
                (ResolvedAuthor.resolve repo (Post.author post))
                (Just <| List.filterMap (\groupId -> Repo.getGroup groupId repo) (Post.groupIds post))
                (Just <| Repo.getSpaceUsers (Post.recipientIds post) repo)
                (Just <| Repo.getPostReactions (Post.id post) repo)

        Nothing ->
            Nothing


unresolve : ResolvedPost -> Id
unresolve post =
    Post.id post.post
