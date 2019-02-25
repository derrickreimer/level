module ResolvedPostWithReplies exposing (ResolvedPostWithReplies, addManyToRepo, addToRepo, decoder, unresolve)

import Connection exposing (Connection)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedAuthor exposing (ResolvedAuthor)
import ResolvedReply exposing (ResolvedReply)
import SpaceUser exposing (SpaceUser)


type alias ResolvedPostWithReplies =
    { post : Post
    , author : ResolvedAuthor
    , groups : List Group
    , reactors : List SpaceUser
    , resolvedReplies : Connection ResolvedReply
    }


decoder : Decoder ResolvedPostWithReplies
decoder =
    Decode.map5 ResolvedPostWithReplies
        Post.decoder
        (field "author" ResolvedAuthor.decoder)
        (field "groups" (list Group.decoder))
        (Decode.at [ "reactions", "edges" ] (list <| Decode.at [ "node", "spaceUser" ] SpaceUser.decoder))
        (field "replies" (Connection.decoder ResolvedReply.decoder))


addToRepo : ResolvedPostWithReplies -> Repo -> Repo
addToRepo post repo =
    repo
        |> Repo.setPost post.post
        |> Repo.setGroups post.groups
        |> ResolvedAuthor.addToRepo post.author
        |> Repo.setSpaceUsers post.reactors
        |> ResolvedReply.addManyToRepo (Connection.toList post.resolvedReplies)


addManyToRepo : List ResolvedPostWithReplies -> Repo -> Repo
addManyToRepo posts repo =
    List.foldr addToRepo repo posts



-- resolve : Repo -> Id -> Int -> Maybe ResolvedPostWithReplies
-- resolve repo postId replyLimit =
--     let
--         maybePost =
--             Repo.getPost postId repo
--     in
--     case maybePost of
--         Just post ->
--             Maybe.map5 ResolvedPostWithReplies
--                 (Just post)
--                 (ResolvedAuthor.resolve repo (Post.author post))
--                 (Just <| List.filterMap (\id -> Repo.getGroup id repo) (Post.groupIds post))
--                 (Just <| Repo.getSpaceUsers (Post.reactorIds post) repo)
--                 (Just <| Connection.filterMap (ResolvedReply.resolve repo) replyIds)
--
--         Nothing ->
--             Nothing


unresolve : ResolvedPostWithReplies -> ( Id, Connection Id )
unresolve post =
    ( Post.id post.post
    , Connection.map ResolvedReply.unresolve post.resolvedReplies
    )
