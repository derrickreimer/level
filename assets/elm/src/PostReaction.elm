module PostReaction exposing
    ( PostReaction
    , fragment
    , decoder
    )

{-| A post reaction represents a "thumbs-up" acknowledgement on a post.


# Types

@docs PostReaction


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Post
import SpaceUser



-- TYPES


type PostReaction
    = PostReaction Data


type alias Data =
    { spaceUserId : Id
    , postId : Id
    }



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment PostReactionFields on PostReaction {
              spaceUser {
                ...SpaceUserFields
              }
              post {
                ...PostFields
              }
            }
            """
    in
    GraphQL.toFragment queryBody
        [ SpaceUser.fragment
        , Post.fragment
        ]



-- DECODERS


decoder : Decoder PostReaction
decoder =
    Decode.map PostReaction <|
        Decode.map2 Data
            (Decode.at [ "spaceUser", "id" ] Id.decoder)
            (Decode.at [ "post", "id" ] Id.decoder)
