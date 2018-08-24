module Reply exposing (Record, Reply, decoder, fragment, getCachedData, getId, getPostId)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, int, string)
import Json.Decode.Pipeline as Pipeline
import SpaceUser exposing (SpaceUser)
import Time exposing (Posix)
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
    , postedAt : Posix
    , fetchedAt : Int
    }


fragment : Fragment
fragment =
    GraphQL.toFragment
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
        [ SpaceUser.fragment
        ]



-- DECODERS


decoder : Decoder Reply
decoder =
    Decode.map Reply <|
        (Decode.succeed Record
            |> Pipeline.required "id" string
            |> Pipeline.required "postId" string
            |> Pipeline.required "body" string
            |> Pipeline.required "bodyHtml" string
            |> Pipeline.required "author" SpaceUser.decoder
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
