module Data.PostConnection exposing (PostConnection, decoder, append)

import Json.Decode as Decode exposing (field, list)
import Data.Post exposing (Post)
import Data.PageInfo exposing (PageInfo)
import Util exposing (memberById)


-- TYPES


type alias PostConnection =
    { nodes : List Post
    , pageInfo : PageInfo
    }



-- DECODERS


decoder : Decode.Decoder PostConnection
decoder =
    Decode.map2 PostConnection
        (field "edges" (list (field "node" Data.Post.decoder)))
        (field "pageInfo" Data.PageInfo.decoder)



-- MUTATIONS


append : Post -> PostConnection -> PostConnection
append post ({ nodes } as connection) =
    if memberById post nodes then
        connection
    else
        { connection | nodes = post :: nodes }
