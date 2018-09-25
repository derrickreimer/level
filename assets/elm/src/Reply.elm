module Reply exposing (Reply, authorId, body, bodyHtml, decoder, fragment, hasViewed, id, postId, postedAt)

import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, field, int, string)
import Json.Decode.Pipeline as Pipeline exposing (required)
import SpaceUser exposing (SpaceUser)
import Time exposing (Posix)
import Util exposing (dateDecoder)



-- TYPES


type Reply
    = Reply Data


type alias Data =
    { id : String
    , postId : String
    , body : String
    , bodyHtml : String
    , authorId : Id
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


authorId : Reply -> Id
authorId (Reply data) =
    data.authorId


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
        (Decode.succeed Data
            |> required "id" Id.decoder
            |> required "postId" Id.decoder
            |> required "body" string
            |> required "bodyHtml" string
            |> required "author" (field "id" Id.decoder)
            |> required "hasViewed" bool
            |> required "postedAt" dateDecoder
            |> required "fetchedAt" int
        )
