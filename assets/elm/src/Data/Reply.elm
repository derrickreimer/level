module Data.Reply exposing (Reply, ReplyConnection, replyDecoder, replyConnectionDecoder)

import Date exposing (Date)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.PageInfo exposing (PageInfo, pageInfoDecoder)
import Data.SpaceUser exposing (SpaceUser, spaceUserDecoder)
import Util exposing (dateDecoder)


-- TYPES


type alias Reply =
    { id : String
    , body : String
    , bodyHtml : String
    , author : SpaceUser
    , postedAt : Date
    }


type alias ReplyConnection =
    { nodes : List Reply
    , pageInfo : PageInfo
    }



-- DECODERS


replyDecoder : Decode.Decoder Reply
replyDecoder =
    Pipeline.decode Reply
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "bodyHtml" Decode.string
        |> Pipeline.required "author" spaceUserDecoder
        |> Pipeline.required "postedAt" dateDecoder


replyConnectionDecoder : Decode.Decoder ReplyConnection
replyConnectionDecoder =
    Pipeline.decode ReplyConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list replyEdgeDecoder))
        |> Pipeline.custom (Decode.at [ "pageInfo" ] pageInfoDecoder)


replyEdgeDecoder : Decode.Decoder Reply
replyEdgeDecoder =
    Decode.at [ "node" ] replyDecoder
