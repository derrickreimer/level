module PostSearchResult exposing
    ( PostSearchResult
    , preview, postId
    , fragment
    , decoder
    )

{-| Represents a post search result item.


# Types

@docs PostSearchResult


# Properties

@docs preview, postId


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, string)
import Post exposing (Post)



-- TYPES


type PostSearchResult
    = PostSearchResult Internal


type alias Internal =
    { preview : String
    , postId : Id
    }



-- PROPERTIES


preview : PostSearchResult -> String
preview (PostSearchResult internal) =
    internal.preview


postId : PostSearchResult -> Id
postId (PostSearchResult internal) =
    internal.postId



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
        Decode.map2 Internal
            (field "preview" string)
            (Decode.at [ "post", "id" ] Id.decoder)
