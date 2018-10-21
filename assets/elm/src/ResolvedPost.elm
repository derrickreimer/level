module ResolvedPost exposing (ResolvedPost, addManyToRepo, addToRepo, decoder, resolve, unresolve)

import Actor exposing (Actor)
import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)


type alias ResolvedPost =
    { post : Post
    , author : Actor
    , groups : List Group
    }


decoder : Decoder ResolvedPost
decoder =
    Decode.map3 ResolvedPost
        Post.decoder
        (field "author" Actor.decoder)
        (field "groups" (list Group.decoder))


addToRepo : ResolvedPost -> Repo -> Repo
addToRepo post repo =
    repo
        |> Repo.setPost post.post
        |> Repo.setGroups post.groups
        |> Repo.setActor post.author


addManyToRepo : List ResolvedPost -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts


resolve : Repo -> Id -> Maybe ResolvedPost
resolve repo postId =
    case Repo.getPost postId repo of
        Just post ->
            Maybe.map3 ResolvedPost
                (Just post)
                (Repo.getActor (Post.authorId post) repo)
                (Just <| List.filterMap (\groupId -> Repo.getGroup groupId repo) (Post.groupIds post))

        Nothing ->
            Nothing


unresolve : ResolvedPost -> Id
unresolve post =
    Post.id post.post
