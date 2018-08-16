module Data.Reply
    exposing
        ( Reply
        , Record
        , fragment
        , decoder
        , getId
        , getPostId
        , getCachedData
        )

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, string, int)
import Json.Decode.Pipeline as Pipeline
import Data.SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Util exposing (dateDecoder)


-- TYPES


type Reply
    = Reply Record


type alias Record =
    { id : String
    , postId : String
    , body : String
    , bodyHtml : String
    , author : SpaceUser
    , postedAt : Date
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.fragment
        """
        fragment ReplyFields on Reply {
          id
          postId
          body
          bodyHtml
          author {
            ...SpaceUserFields
          }
          postedAt
          fetchedAt
        }
        """
        [ Data.SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder Reply
decoder =
    Decode.map Reply <|
        (Pipeline.decode Record
            |> Pipeline.required "id" string
            |> Pipeline.required "postId" string
            |> Pipeline.required "body" string
            |> Pipeline.required "bodyHtml" string
            |> Pipeline.required "author" Data.SpaceUser.decoder
            |> Pipeline.required "postedAt" dateDecoder
            |> Pipeline.required "fetchedAt" int
        )



-- API


getId : Reply -> String
getId (Reply { id }) =
    id


getPostId : Reply -> String
getPostId (Reply { postId }) =
    postId


getCachedData : Reply -> Record
getCachedData (Reply data) =
    data
