module ResolvedPostSearchResult exposing (ResolvedPostSearchResult, addToRepo, decoder, resolve, unresolve)

import Json.Decode as Decode exposing (Decoder, field, list, maybe)
import PostSearchResult exposing (PostSearchResult)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import ResolvedReply exposing (ResolvedReply)


type alias ResolvedPostSearchResult =
    { result : PostSearchResult
    , resolvedPost : ResolvedPost
    }


decoder : Decoder ResolvedPostSearchResult
decoder =
    Decode.map2 ResolvedPostSearchResult
        PostSearchResult.decoder
        (field "post" ResolvedPost.decoder)


addToRepo : ResolvedPostSearchResult -> Repo -> Repo
addToRepo result repo =
    repo
        |> ResolvedPost.addToRepo result.resolvedPost


resolve : Repo -> PostSearchResult -> Maybe ResolvedPostSearchResult
resolve repo result =
    Maybe.map2 ResolvedPostSearchResult
        (Just result)
        (ResolvedPost.resolve repo (PostSearchResult.postId result))


unresolve : ResolvedPostSearchResult -> PostSearchResult
unresolve resolvedResult =
    resolvedResult.result
