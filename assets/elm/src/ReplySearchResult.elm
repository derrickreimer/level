module ReplySearchResult exposing
    ( ReplySearchResult
    , preview, postId, replyId
    , fragment
    , decoder
    )

{-| Represents a post search result item.


# Types

@docs ReplySearchResult


# Properties

@docs preview, postId, replyId


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



-- TYPES


type ReplySearchResult
    = ReplySearchResult Internal


type alias Internal =
    { preview : String
    , postId : Id
    , replyId : Id
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
        Decode.map3 Internal
            (field "preview" string)
            (Decode.at [ "post", "id" ] Id.decoder)
            (Decode.at [ "reply", "id" ] Id.decoder)
