module ResolvedSearchResult exposing (ResolvedSearchResult(..), addToRepo, decoder, resolve, unresolve)

import Json.Decode as Decode exposing (Decoder, field, string)
import Repo exposing (Repo)
import ResolvedPostSearchResult exposing (ResolvedPostSearchResult)
import ResolvedReplySearchResult exposing (ResolvedReplySearchResult)
import SearchResult exposing (SearchResult)


type ResolvedSearchResult
    = Post ResolvedPostSearchResult
    | Reply ResolvedReplySearchResult


addToRepo : ResolvedSearchResult -> Repo -> Repo
addToRepo resolvedResult repo =
    case resolvedResult of
        Post result ->
            ResolvedPostSearchResult.addToRepo result repo

        Reply result ->
            ResolvedReplySearchResult.addToRepo result repo


decoder : Decoder ResolvedSearchResult
decoder =
    field "__typename" string
        |> Decode.andThen resultDecoder


resultDecoder : String -> Decoder ResolvedSearchResult
resultDecoder typename =
    case typename of
        "PostSearchResult" ->
            Decode.map Post ResolvedPostSearchResult.decoder

        "ReplySearchResult" ->
            Decode.map Reply ResolvedReplySearchResult.decoder

        _ ->
            Decode.fail "result type not recognized"


resolve : Repo -> SearchResult -> Maybe ResolvedSearchResult
resolve repo result =
    case result of
        SearchResult.Post data ->
            Maybe.map Post
                (ResolvedPostSearchResult.resolve repo data)

        SearchResult.Reply data ->
            Maybe.map Reply
                (ResolvedReplySearchResult.resolve repo data)


unresolve : ResolvedSearchResult -> SearchResult
unresolve resolvedResult =
    case resolvedResult of
        Post result ->
            SearchResult.Post <|
                ResolvedPostSearchResult.unresolve result

        Reply result ->
            SearchResult.Reply <|
                ResolvedReplySearchResult.unresolve result
