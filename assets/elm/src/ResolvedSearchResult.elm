module ResolvedSearchResult exposing (ResolvedSearchResult, addToRepo, decoder, unresolve)

import Id exposing (Id)
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
