module Data.ReplyConnection exposing (ReplyConnection, decoder)

import Json.Decode as Decode exposing (Decoder, field, list)
import Data.PageInfo exposing (PageInfo)
import Data.Reply exposing (Reply)


-- TYPES


type alias ReplyConnection =
    { nodes : List Reply
    , pageInfo : PageInfo
    }



-- DECODERS


decoder : Decoder ReplyConnection
decoder =
    Decode.map2 ReplyConnection
        (field "edges" (list (field "node" Data.Reply.decoder)))
        (field "pageInfo" Data.PageInfo.decoder)
