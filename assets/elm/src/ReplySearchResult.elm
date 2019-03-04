module ReplySearchResult exposing
    ( ReplySearchResult
    , preview, postId, replyId, postedAt
    , fragment
    , decoder
    )

{-| Represents a post search result item.


# Types

@docs ReplySearchResult


# Properties

@docs preview, postId, replyId, postedAt


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, string)
import Post exposing (Post)
import Reply exposing (Reply)
import Time exposing (Posix)
import Util exposing (dateDecoder)



-- TYPES


type ReplySearchResult
    = ReplySearchResult Internal


type alias Internal =
    { preview : String
    , postId : Id
    , replyId : Id
    , postedAt : Posix
    }



-- PROPERTIES


preview : ReplySearchResult -> String
preview (ReplySearchResult internal) =
    internal.preview


postId : ReplySearchResult -> Id
postId (ReplySearchResult internal) =
    internal.postId


replyId : ReplySearchResult -> Id
replyId (ReplySearchResult internal) =
    internal.replyId


postedAt : ReplySearchResult -> Posix
postedAt (ReplySearchResult internal) =
    internal.postedAt



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment ReplySearchResultFields on ReplySearchResult {
              preview
              post {
                ...PostFields
              }
              reply {
                ...ReplyFields
              }
              postedAt
            }
            """
    in
    GraphQL.toFragment queryBody
        [ Post.fragment
        , Reply.fragment
        ]



-- DECODERS


decoder : Decoder ReplySearchResult
decoder =
    Decode.map ReplySearchResult <|
        Decode.map4 Internal
            (field "preview" string)
            (Decode.at [ "post", "id" ] Id.decoder)
            (Decode.at [ "reply", "id" ] Id.decoder)
            (field "postedAt" dateDecoder)
