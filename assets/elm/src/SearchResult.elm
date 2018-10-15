module SearchResult exposing
    ( SearchResult
    , preview, postId, replyId
    , fragment
    , decoder
    )

{-| Represents a search result item.


# Types

@docs SearchResult


# Properties

@docs preview, postId, replyId


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
import Reply exposing (Reply)



-- TYPES


type SearchResult
    = SearchResult Data


type alias Data =
    { preview : String
    , postId : Id
    , replyId : Maybe Id
    }



-- PROPERTIES


preview : SearchResult -> String
preview (SearchResult data) =
    data.preview


postId : SearchResult -> Id
postId (SearchResult data) =
    data.postId


replyId : SearchResult -> Maybe Id
replyId (SearchResult data) =
    data.replyId



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment SearchResultFields on SearchResult {
              preview
              post {
                ...PostFields
                replies(first: 5) {
                  ...ReplyConnectionFields
                }
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
        , Connection.fragment "ReplyConnection" Reply.fragment
        ]



-- DECODERS


decoder : Decoder SearchResult
decoder =
    Decode.map SearchResult <|
        Decode.map3 Data
            (field "preview" string)
            (Decode.at [ "post", "id" ] Id.decoder)
            (Decode.at [ "reply" ] (maybe (field "id" Id.decoder)))
