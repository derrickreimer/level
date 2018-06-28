module Data.Reply exposing (Reply, replyDecoder)

import Date exposing (Date)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.SpaceUser exposing (SpaceUser, spaceUserDecoder)
import Util exposing (dateDecoder)


-- TYPES


type alias Reply =
    { id : String
    , postId : String
    , body : String
    , bodyHtml : String
    , author : SpaceUser
    , postedAt : Date
    }



-- DECODERS


replyDecoder : Decode.Decoder Reply
replyDecoder =
    Pipeline.decode Reply
        |> Pipeline.required "id" Decode.string
        |> Pipeline.custom (Decode.at [ "post", "id" ] Decode.string)
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "bodyHtml" Decode.string
        |> Pipeline.required "author" spaceUserDecoder
        |> Pipeline.required "postedAt" dateDecoder
