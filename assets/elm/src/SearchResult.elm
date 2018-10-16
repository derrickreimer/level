module SearchResult exposing
    ( SearchResult(..)
    , fragment
    , decoder
    )

{-| Represents a search result item.


# Types

@docs SearchResult


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import Connection exposing (Connection)
import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, maybe, string)
import Post exposing (Post)
import PostSearchResult exposing (PostSearchResult)
import Reply exposing (Reply)
import ReplySearchResult exposing (ReplySearchResult)



-- TYPES


type SearchResult
    = Post PostSearchResult
    | Reply ReplySearchResult



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment SearchResultFields on SearchResult {
              __typename

              ... on PostSearchResult {
                ...PostSearchResultFields
              }

              ... on ReplySearchResult {
                ...ReplySearchResultFields
              }
            }
            """
    in
    GraphQL.toFragment queryBody
        [ PostSearchResult.fragment
        , ReplySearchResult.fragment
        ]



-- DECODERS


decoder : Decoder SearchResult
decoder =
    field "__typename" string
        |> Decode.andThen resultDecoder


resultDecoder : String -> Decoder SearchResult
resultDecoder typename =
    case typename of
        "PostSearchResult" ->
            Decode.map Post PostSearchResult.decoder

        "ReplySearchResult" ->
            Decode.map Reply ReplySearchResult.decoder

        _ ->
            Decode.fail "result type not recognized"
