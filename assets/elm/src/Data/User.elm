module Data.User
    exposing
        ( User
        , UserConnection
        , UserEdge
        , userDecoder
        , userConnectionDecoder
        , displayName
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.PageInfo exposing (PageInfo, pageInfoDecoder)


-- TYPES


type alias UserConnection =
    { edges : List UserEdge
    , pageInfo : PageInfo
    }


type alias UserEdge =
    { node : User
    }


type alias User =
    { id : String
    , firstName : String
    , lastName : String
    }



-- DECODERS


userConnectionDecoder : Decode.Decoder UserConnection
userConnectionDecoder =
    Pipeline.decode UserConnection
        |> Pipeline.custom (Decode.at [ "edges" ] (Decode.list userEdgeDecoder))
        |> Pipeline.custom (Decode.at [ "pageInfo" ] pageInfoDecoder)


userEdgeDecoder : Decode.Decoder UserEdge
userEdgeDecoder =
    Pipeline.decode UserEdge
        |> Pipeline.custom (Decode.at [ "node" ] userDecoder)


userDecoder : Decode.Decoder User
userDecoder =
    Pipeline.decode User
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "firstName" Decode.string
        |> Pipeline.required "lastName" Decode.string



-- UTILS


{-| Generate the display name for a given user.

    displayName { firstName = "Derrick", lastName = "Reimer" } == "Derrick Reimer"

-}
displayName : User -> String
displayName user =
    user.firstName ++ " " ++ user.lastName
