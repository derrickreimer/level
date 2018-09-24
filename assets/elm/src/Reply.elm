module Reply exposing (Record, Reply, author, body, bodyHtml, decoder, fragment, hasViewed, id, postId, postedAt)

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, int, string)
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
    , hasViewed : Bool
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
          hasViewed
          postedAt
          fetchedAt
        }
        """
        [ SpaceUser.fragment
        ]



-- ACCESSORS


id : Reply -> Id
id (Reply data) =
    data.id


postId : Reply -> Id
postId (Reply data) =
    data.postId


body : Reply -> String
body (Reply data) =
    data.body


bodyHtml : Reply -> String
bodyHtml (Reply data) =
    data.bodyHtml


author : Reply -> SpaceUser
author (Reply data) =
    data.author


hasViewed : Reply -> Bool
hasViewed (Reply data) =
    data.hasViewed


postedAt : Reply -> Posix
postedAt (Reply data) =
    data.postedAt



-- DECODERS


decoder : Decoder Reply
decoder =
    Decode.map Reply <|
        (Decode.succeed Record
            |> Pipeline.required "id" Id.decoder
            |> Pipeline.required "postId" Id.decoder
            |> Pipeline.required "body" string
            |> Pipeline.required "bodyHtml" string
            |> Pipeline.required "author" SpaceUser.decoder
            |> Pipeline.required "hasViewed" bool
            |> Pipeline.required "postedAt" dateDecoder
            |> Pipeline.required "fetchedAt" int
        )
