module PostReaction exposing
    ( PostReaction
    , id, spaceUserId, postId, value
    , fragment
    , decoder
    )

{-| A post reaction represents a "thumbs-up" acknowledgement on a post.


# Types

@docs PostReaction


# API

@docs id, spaceUserId, postId, value


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import SpaceUser



-- TYPES


type PostReaction
    = PostReaction Data


type alias Data =
    { id : Id
    , spaceUserId : Id
    , postId : Id
    , value : String
    }



-- API


id : PostReaction -> Id
id (PostReaction data) =
    data.id


spaceUserId : PostReaction -> Id
spaceUserId (PostReaction data) =
    data.spaceUserId


postId : PostReaction -> Id
postId (PostReaction data) =
    data.postId


value : PostReaction -> String
value (PostReaction data) =
    data.value



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
                id
              }
              value
            }
            """
    in
    GraphQL.toFragment queryBody
        [ SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder PostReaction
decoder =
    Decode.map PostReaction <|
        Decode.map4 Data
            (Decode.field "id" Id.decoder)
            (Decode.at [ "spaceUser", "id" ] Id.decoder)
            (Decode.at [ "post", "id" ] Id.decoder)
            (Decode.field "value" Decode.string)
