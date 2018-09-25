module ResolvedReply exposing (ResolvedReply, addManyToRepo, addToRepo, decoder, unresolve)

import Connection exposing (Connection)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Reply exposing (Reply)
import Repo exposing (Repo)
import SpaceUser exposing (SpaceUser)


type alias ResolvedReply =
    { reply : Reply
    , author : SpaceUser
    }


decoder : Decoder ResolvedReply
decoder =
    Decode.map2 ResolvedReply
        Reply.decoder
        (field "author" SpaceUser.decoder)


addToRepo : ResolvedReply -> Repo -> Repo
addToRepo resolvedReply repo =
    repo
        |> Repo.setReply resolvedReply.reply
        |> Repo.setSpaceUser resolvedReply.author


addManyToRepo : List ResolvedReply -> Repo -> Repo
addManyToRepo resolvedReplies repo =
    List.foldr addToRepo repo resolvedReplies


unresolve : ResolvedReply -> Id
unresolve resolvedReply =
    Reply.id resolvedReply.reply
