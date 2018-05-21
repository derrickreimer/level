module Data.Post exposing (Post, postDecoder)

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline
import Data.Group exposing (Group, groupDecoder)
import Data.SpaceUser exposing (SpaceUser, spaceUserDecoder)


-- TYPES


type alias Post =
    { id : String
    , body : String
    , author : SpaceUser
    , groups : List Group
    }



-- DECODERS


postDecoder : Decode.Decoder Post
postDecoder =
    Pipeline.decode Post
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "author" spaceUserDecoder
        |> Pipeline.required "groups" (Decode.list groupDecoder)
