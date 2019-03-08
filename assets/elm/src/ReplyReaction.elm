module ReplyReaction exposing
    ( ReplyReaction
    , spaceUserId, postId, replyId
    , fragment
    , decoder
    )

{-| A reply reaction represents a "thumbs-up" acknowledgement on a reply.


# Types

@docs ReplyReaction


# API

@docs spaceUserId, postId, replyId


# GraphQL

@docs fragment


# Decoders

@docs decoder

-}

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Post
import Reply
import SpaceUser



-- TYPES


type ReplyReaction
    = ReplyReaction Data


type alias Data =
    { spaceUserId : Id
    , postId : Id
    , replyId : Id
    }



-- API


spaceUserId : ReplyReaction -> Id
spaceUserId (ReplyReaction data) =
    data.spaceUserId


postId : ReplyReaction -> Id
postId (ReplyReaction data) =
    data.postId


replyId : ReplyReaction -> Id
replyId (ReplyReaction data) =
    data.replyId



-- GRAPHQL


fragment : Fragment
fragment =
    let
        queryBody =
            """
            fragment ReplyReactionFields on ReplyReaction {
              spaceUser {
                ...SpaceUserFields
              }
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
        [ SpaceUser.fragment
        , Post.fragment
        , Reply.fragment
        ]



-- DECODERS


decoder : Decoder ReplyReaction
decoder =
    Decode.map ReplyReaction <|
        Decode.map3 Data
            (Decode.at [ "spaceUser", "id" ] Id.decoder)
            (Decode.at [ "post", "id" ] Id.decoder)
            (Decode.at [ "reply", "id" ] Id.decoder)
