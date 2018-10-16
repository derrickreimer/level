module ResolvedSearchResult exposing (ResolvedSearchResult, addToRepo, decoder, resolve, unresolve)

import Json.Decode as Decode exposing (Decoder, field, list, maybe)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import ResolvedReply exposing (ResolvedReply)
import SearchResult exposing (SearchResult)


type alias ResolvedSearchResult =
    { searchResult : SearchResult
    , resolvedPost : ResolvedPost
    , resolvedReply : Maybe ResolvedReply
    }


decoder : Decoder ResolvedSearchResult
decoder =
    Decode.map3 ResolvedSearchResult
        SearchResult.decoder
        (field "post" ResolvedPost.decoder)
        (field "reply" (maybe ResolvedReply.decoder))


addToRepo : ResolvedSearchResult -> Repo -> Repo
addToRepo result repo =
    repo
        |> ResolvedPost.addToRepo result.resolvedPost
        |> addMaybeReplyToRepo result.resolvedReply


resolve : Repo -> SearchResult -> Maybe ResolvedSearchResult
resolve repo result =
    case ResolvedPost.resolve repo (SearchResult.postId result) of
        Just post ->
            let
                reply =
                    case SearchResult.replyId result of
                        Just replyId ->
                            ResolvedReply.resolve repo replyId

                        Nothing ->
                            Nothing
            in
            Just (ResolvedSearchResult result post reply)

        Nothing ->
            Nothing


unresolve : ResolvedSearchResult -> SearchResult
unresolve result =
    result.searchResult



-- INTERNAL


addMaybeReplyToRepo : Maybe ResolvedReply -> Repo -> Repo
addMaybeReplyToRepo maybeReply repo =
    case maybeReply of
        Just reply ->
            ResolvedReply.addToRepo reply repo

        Nothing ->
            repo
