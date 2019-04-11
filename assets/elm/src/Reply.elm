module Reply exposing (Reply, asc, author, body, bodyHtml, canEdit, decoder, desc, files, fragment, hasViewed, id, notDeleted, postId, postedAt, reactionCount, reactorIds, url)

import Author exposing (Author)
import File exposing (File)
import GraphQL exposing (Fragment)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, bool, field, int, string)
import Json.Decode.Pipeline as Pipeline exposing (custom, required)
import ReplyReaction exposing (ReplyReaction)
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
    , author : Author
    , files : List File
    , hasViewed : Bool
    , reactionCount : Int
    , reactorIds : List Id
    , url : String
    , isDeleted : Bool
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
            ...AuthorFields
          }
          files {
            ...FileFields
          }
          hasViewed
          reactions(first: 100) {
            edges {
              node {
                ...ReplyReactionFields
              }
            }
            totalCount
          }
          url
          isDeleted
          canEdit
          postedAt
          fetchedAt
        }
        """
        [ Author.fragment
        , File.fragment
        , ReplyReaction.fragment
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


author : Reply -> Author
author (Reply data) =
    data.author


files : Reply -> List File
files (Reply data) =
    data.files


url : Reply -> String
url (Reply data) =
    data.url


hasViewed : Reply -> Bool
hasViewed (Reply data) =
    data.hasViewed


reactionCount : Reply -> Int
reactionCount (Reply data) =
    data.reactionCount


reactorIds : Reply -> List Id
reactorIds (Reply data) =
    data.reactorIds


notDeleted : Reply -> Bool
notDeleted (Reply data) =
    not data.isDeleted


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
            |> required "author" Author.decoder
            |> required "files" (Decode.list File.decoder)
            |> required "hasViewed" bool
            |> custom (Decode.at [ "reactions", "totalCount" ] int)
            |> custom (Decode.at [ "reactions", "edges" ] (Decode.list <| Decode.at [ "node", "spaceUser", "id" ] Id.decoder))
            |> required "url" string
            |> required "isDeleted" bool
            |> required "canEdit" bool
            |> required "postedAt" dateDecoder
            |> required "fetchedAt" int
        )



-- SORTING


asc : Reply -> Reply -> Order
asc (Reply a) (Reply b) =
    compare (Time.posixToMillis a.postedAt) (Time.posixToMillis b.postedAt)


desc : Reply -> Reply -> Order
desc (Reply a) (Reply b) =
    let
        ac =
            Time.posixToMillis a.postedAt

        bc =
            Time.posixToMillis b.postedAt
    in
    case compare ac bc of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT
