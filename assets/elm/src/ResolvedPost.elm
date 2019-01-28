module ResolvedPost exposing (ResolvedPost, addManyToRepo, addToRepo, decoder, resolve, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedAuthor exposing (ResolvedAuthor)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPost =
    { post : Post
    , author : ResolvedAuthor
    , groups : List Group
    , reactors : List SpaceUser
    }


decoder : Decoder ResolvedPost
decoder =
    Decode.map4 ResolvedPost
        Post.decoder
        (field "author" ResolvedAuthor.decoder)
        (field "groups" (list Group.decoder))
        (Decode.at [ "reactions", "edges" ] (list <| Decode.at [ "node", "spaceUser" ] SpaceUser.decoder))


addToRepo : ResolvedPost -> Repo -> Repo
addToRepo post repo =
    repo
        |> Repo.setPost post.post
        |> Repo.setGroups post.groups
        |> ResolvedAuthor.addToRepo post.author
        |> Repo.setSpaceUsers post.reactors


addManyToRepo : List ResolvedPost -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts


resolve : Repo -> Id -> Maybe ResolvedPost
resolve repo postId =
    case Repo.getPost postId repo of
        Just post ->
            Maybe.map4 ResolvedPost
                (Just post)
                (ResolvedAuthor.resolve repo (Post.author post))
                (Just <| List.filterMap (\groupId -> Repo.getGroup groupId repo) (Post.groupIds post))
                (Just <| Repo.getSpaceUsers (Post.reactorIds post) repo)

        Nothing ->
            Nothing


unresolve : ResolvedPost -> Id
unresolve post =
    Post.id post.post
