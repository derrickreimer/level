module ResolvedPost exposing (ResolvedPost, addManyToRepo, addToRepo, decoder, resolve, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPost =
    { post : Post
    , author : SpaceUser
    , groups : List Group
    }


decoder : Decoder ResolvedPost
decoder =
    Decode.map3 ResolvedPost
        Post.decoder
        (field "author" SpaceUser.decoder)
        (field "groups" (list Group.decoder))


addToRepo : ResolvedPost -> Repo -> Repo
addToRepo post repo =
    repo
        |> Repo.setPost post.post
        |> Repo.setSpaceUser post.author
        |> Repo.setGroups post.groups


addManyToRepo : List ResolvedPost -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts


resolve : Repo -> Id -> Maybe ResolvedPost
resolve repo postId =
    case Repo.getPost postId repo of
        Just post ->
            Maybe.map3 ResolvedPost
                (Just post)
                (Repo.getSpaceUser (Post.authorId post) repo)
                (Just <| List.filterMap (\groupId -> Repo.getGroup groupId repo) (Post.groupIds post))

        Nothing ->
            Nothing


unresolve : ResolvedPost -> Id
unresolve post =
    Post.id post.post
