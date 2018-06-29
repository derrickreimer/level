module Data.Post exposing (Post, PostConnection, postDecoder, postConnectionDecoder, add)

import Date exposing (Date)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Group exposing (Group, groupDecoder)
import Data.PageInfo exposing (PageInfo, pageInfoDecoder)
import Data.Reply exposing (ReplyConnection, replyConnectionDecoder)
import Data.SpaceUser exposing (SpaceUser, spaceUserDecoder)
import Util exposing (dateDecoder, memberById)


-- TYPES


type alias Post =
    { id : String
    , body : String
    , bodyHtml : String
    , author : SpaceUser
    , groups : List Group
    , postedAt : Date
    , replies : ReplyConnection
    }


type alias PostConnection =
    { nodes : List Post
    , pageInfo : PageInfo
    }



-- DECODERS


postDecoder : Decode.Decoder Post
postDecoder =
    Pipeline.decode Post
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "bodyHtml" Decode.string
        |> Pipeline.required "author" spaceUserDecoder
        |> Pipeline.required "groups" (Decode.list groupDecoder)
        |> Pipeline.required "postedAt" dateDecoder
        |> Pipeline.required "replies" replyConnectionDecoder


postConnectionDecoder : Decode.Decoder PostConnection
postConnectionDecoder =
    Pipeline.decode PostConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list postEdgeDecoder))
        |> Pipeline.custom (Decode.at [ "pageInfo" ] pageInfoDecoder)


postEdgeDecoder : Decode.Decoder Post
postEdgeDecoder =
    Decode.at [ "node" ] postDecoder



-- MUTATIONS


add : Post -> PostConnection -> PostConnection
add post ({ nodes } as connection) =
    if memberById post nodes then
        connection
    else
        { connection | nodes = post :: nodes }
