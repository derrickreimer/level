module ReplyReaction exposing
    ( ReplyReaction
    , id, spaceUserId, postId, replyId, value
    , fragment
    , decoder
    )

{-| A reply reaction represents a "thumbs-up" acknowledgement on a reply.


# Types

@docs ReplyReaction


# API

@docs id, spaceUserId, postId, replyId, value


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


type ReplyReaction
    = ReplyReaction Data


type alias Data =
    { id : Id
    , spaceUserId : Id
    , postId : Id
    , replyId : Id
    , value : String
    }



-- API


id : ReplyReaction -> Id
id (ReplyReaction data) =
    data.id


spaceUserId : ReplyReaction -> Id
spaceUserId (ReplyReaction data) =
    data.spaceUserId


postId : ReplyReaction -> Id
postId (ReplyReaction data) =
    data.postId


replyId : ReplyReaction -> Id
replyId (ReplyReaction data) =
    data.replyId


value : ReplyReaction -> String
value (ReplyReaction data) =
    data.value



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
                id
              }
              reply {
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


decoder : Decoder ReplyReaction
decoder =
    Decode.map ReplyReaction <|
        Decode.map5 Data
            (Decode.field "id" Id.decoder)
            (Decode.at [ "spaceUser", "id" ] Id.decoder)
            (Decode.at [ "post", "id" ] Id.decoder)
            (Decode.at [ "reply", "id" ] Id.decoder)
            (Decode.field "value" Decode.string)
