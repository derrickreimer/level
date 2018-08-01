module Data.Post
    exposing
        ( Post
        , fragment
        , decoder
        , getId
        , getCachedData
        , hasReplies
        , prependReplies
        , appendReply
        , groupsInclude
        )

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, list, string)
import Json.Decode.Pipeline as Pipeline
import String.Interpolate exposing (interpolate)
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import Data.Reply as Reply exposing (Reply)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Util exposing (dateDecoder)


-- TYPES


type Post
    = Post Record


type alias Record =
    { id : String
    , body : String
    , bodyHtml : String
    , author : SpaceUser
    , groups : List Group
    , postedAt : Date
    , replies : Connection Reply
    }


fragment : Int -> Fragment
fragment replyLimit =
    let
        body =
            interpolate
                """
                fragment PostFields on Post {
                  id
                  body
                  bodyHtml
                  postedAt
                  subscriptionState
                  author {
                    ...SpaceUserFields
                  }
                  groups {
                    ...GroupFields
                  }
                  replies(last: {0}) {
                    ...ReplyConnectionFields
                  }
                }
                """
                [ toString replyLimit
                ]
    in
        GraphQL.fragment body
            [ SpaceUser.fragment
            , Group.fragment
            , Connection.fragment "ReplyConnection" Reply.fragment
            ]



-- DECODERS


decoder : Decoder Post
decoder =
    Decode.map Post <|
        (Pipeline.decode Record
            |> Pipeline.required "id" string
            |> Pipeline.required "body" string
            |> Pipeline.required "bodyHtml" string
            |> Pipeline.required "author" SpaceUser.decoder
            |> Pipeline.required "groups" (list Group.decoder)
            |> Pipeline.required "postedAt" dateDecoder
            |> Pipeline.required "replies" (Connection.decoder Reply.decoder)
        )



-- CRUD


getId : Post -> String
getId (Post { id }) =
    id


getCachedData : Post -> Record
getCachedData (Post data) =
    data


hasReplies : Post -> Bool
hasReplies (Post { replies }) =
    not (Connection.isEmpty replies)


prependReplies : Connection Reply -> Post -> Post
prependReplies replies (Post data) =
    Post { data | replies = Connection.prependConnection replies data.replies }


appendReply : Reply -> Post -> Post
appendReply reply (Post data) =
    Post { data | replies = Connection.append Reply.getId reply data.replies }


groupsInclude : Group -> Post -> Bool
groupsInclude group (Post data) =
    List.filter (\g -> (Group.getId g) == (Group.getId group)) data.groups
        |> List.isEmpty
        |> not
