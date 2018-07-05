module Data.PostConnection exposing (PostConnection, decoder, get, update, append)

import Json.Decode as Decode exposing (Decoder, field, list)
import Data.Post exposing (Post)
import Data.PageInfo exposing (PageInfo)
import Util exposing (getById, memberById)


-- TYPES


type alias PostConnection =
    { nodes : List Post
    , pageInfo : PageInfo
    }



-- DECODERS


decoder : Decoder PostConnection
decoder =
    Decode.map2 PostConnection
        (field "edges" (list (field "node" Data.Post.decoder)))
        (field "pageInfo" Data.PageInfo.decoder)



-- CRUD


get : String -> PostConnection -> Maybe Post
get id { nodes } =
    getById id nodes


update : Post -> PostConnection -> PostConnection
update post ({ nodes } as connection) =
    let
        replacer node =
            if node.id == post.id then
                post
            else
                node

        newNodes =
            List.map replacer nodes
    in
        { connection | nodes = newNodes }


append : Post -> PostConnection -> PostConnection
append post ({ nodes } as connection) =
    if memberById post nodes then
        connection
    else
        { connection | nodes = post :: nodes }
