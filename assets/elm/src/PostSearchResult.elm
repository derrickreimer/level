module PostSearchResult exposing
    ( PostSearchResult
    , preview, postId, postedAt
    , fragment
    , decoder
    )

{-| Represents a post search result item.


# Types

@docs PostSearchResult


# Properties

@docs preview, postId, postedAt


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, string)
import Post exposing (Post)
import Time exposing (Posix)
import Util exposing (dateDecoder)



-- TYPES


type PostSearchResult
    = PostSearchResult Internal


type alias Internal =
    { preview : String
    , postId : Id
    , postedAt : Posix
    }



-- PROPERTIES


preview : PostSearchResult -> String
preview (PostSearchResult internal) =
    internal.preview


postId : PostSearchResult -> Id
postId (PostSearchResult internal) =
    internal.postId


postedAt : PostSearchResult -> Posix
postedAt (PostSearchResult internal) =
    internal.postedAt



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment PostSearchResultFields on PostSearchResult {
              preview
              post {
                ...PostFields
              }
              postedAt
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Post.fragment
        ]



-- DECODERS


decoder : Decoder PostSearchResult
decoder =
    Decode.map PostSearchResult <|
        Decode.map3 Internal
            (field "preview" string)
            (Decode.at [ "post", "id" ] Id.decoder)
            (field "postedAt" dateDecoder)
