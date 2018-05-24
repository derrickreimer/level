module Data.GroupUser
    exposing
        ( GroupUser
        , GroupUserConnection
        , GroupUserEdge
        , groupUserDecoder
        , groupUserConnectionDecoder
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.PageInfo exposing (PageInfo, pageInfoDecoder)
import Data.SpaceUser exposing (SpaceUser, spaceUserDecoder)


-- TYPES


type alias GroupUserConnection =
    { edges : List GroupUserEdge
    , pageInfo : PageInfo
    }


type alias GroupUserEdge =
    { node : GroupUser
    }


type alias GroupUser =
    { user : SpaceUser
    }



-- DECODERS


groupUserConnectionDecoder : Decode.Decoder GroupUserConnection
groupUserConnectionDecoder =
    Pipeline.decode GroupUserConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list groupUserEdgeDecoder))
        |> Pipeline.custom (Decode.at [ "pageInfo" ] pageInfoDecoder)


groupUserEdgeDecoder : Decode.Decoder GroupUserEdge
groupUserEdgeDecoder =
    Pipeline.decode GroupUserEdge
        |> Pipeline.custom (Decode.at [ "node" ] groupUserDecoder)


groupUserDecoder : Decode.Decoder GroupUser
groupUserDecoder =
    Pipeline.decode GroupUser
        |> Pipeline.required "spaceUser" spaceUserDecoder
