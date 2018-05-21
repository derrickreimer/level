module Data.Post exposing (Post, postDecoder)

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline
import Data.Group exposing (Group, groupDecoder)
import Data.User exposing (User, userDecoder)


-- TYPES


type alias Post =
    { id : String
    , body : String
    , user : User
    , groups : List Group
    }



-- DECODERS


postDecoder : Decode.Decoder Post
postDecoder =
    Pipeline.decode Post
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "user" userDecoder
        |> Pipeline.required "groups" (Decode.list groupDecoder)
