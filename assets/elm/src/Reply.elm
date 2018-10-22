module Reply exposing (Reply, authorId, body, bodyHtml, canEdit, decoder, files, fragment, hasViewed, id, postId, postedAt)

import Actor exposing (ActorId)
import File exposing (File)
import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, field, int, string)
import Json.Decode.Pipeline as Pipeline exposing (required)
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
    , authorId : ActorId
    , files : List File
    , hasViewed : Bool
    , canEdit : Bool
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
            ...ActorFields
          }
          files {
            ...FileFields
          }
          hasViewed
          canEdit
          postedAt
          fetchedAt
        }
        """
        [ Actor.fragment
        , File.fragment
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


authorId : Reply -> ActorId
authorId (Reply data) =
    data.authorId


files : Reply -> List File
files (Reply data) =
    data.files


hasViewed : Reply -> Bool
hasViewed (Reply data) =
    data.hasViewed


canEdit : Reply -> Bool
canEdit (Reply data) =
    data.canEdit


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
            |> required "author" Actor.idDecoder
            |> required "files" (Decode.list File.decoder)
            |> required "hasViewed" bool
            |> required "canEdit" bool
            |> required "postedAt" dateDecoder
            |> required "fetchedAt" int
        )
