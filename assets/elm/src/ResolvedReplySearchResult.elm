module ResolvedReplySearchResult exposing (ResolvedReplySearchResult, addToRepo, decoder, resolve, unresolve)

import Json.Decode as Decode exposing (Decoder, field, list, maybe)
import ReplySearchResult exposing (ReplySearchResult)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import ResolvedReply exposing (ResolvedReply)


type alias ResolvedReplySearchResult =
    { result : ReplySearchResult
    , resolvedPost : ResolvedPost
    , resolvedReply : ResolvedReply
    }


decoder : Decoder ResolvedReplySearchResult
decoder =
    Decode.map3 ResolvedReplySearchResult
        ReplySearchResult.decoder
        (field "post" ResolvedPost.decoder)
        (field "reply" ResolvedReply.decoder)


addToRepo : ResolvedReplySearchResult -> Repo -> Repo
addToRepo result repo =
    repo
        |> ResolvedPost.addToRepo result.resolvedPost
        |> ResolvedReply.addToRepo result.resolvedReply


resolve : Repo -> ReplySearchResult -> Maybe ResolvedReplySearchResult
resolve repo result =
    Maybe.map3 ResolvedReplySearchResult
        (Just result)
        (ResolvedPost.resolve repo (ReplySearchResult.postId result))
        (ResolvedReply.resolve repo (ReplySearchResult.replyId result))


unresolve : ResolvedReplySearchResult -> ReplySearchResult
unresolve resolvedResult =
    resolvedResult.result
