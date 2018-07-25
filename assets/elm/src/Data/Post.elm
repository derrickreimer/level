module Data.Post
    exposing
        ( Post
        , fragment
        , decoder
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
import Data.SpaceUser exposing (SpaceUser)
import GraphQL exposing (Fragment)
import Util exposing (dateDecoder)


-- TYPES


type alias Post =
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
            [ Data.SpaceUser.fragment
            , Group.fragment
            , Connection.fragment "ReplyConnection" Reply.fragment
            ]



-- DECODERS


decoder : Decoder Post
decoder =
    Pipeline.decode Post
        |> Pipeline.required "id" string
        |> Pipeline.required "body" string
        |> Pipeline.required "bodyHtml" string
        |> Pipeline.required "author" Data.SpaceUser.decoder
        |> Pipeline.required "groups" (list Group.decoder)
        |> Pipeline.required "postedAt" dateDecoder
        |> Pipeline.required "replies" (Connection.decoder Reply.decoder)



-- CRUD


prependReplies : Connection Reply -> Post -> Post
prependReplies replies post =
    { post | replies = Connection.prependConnection replies post.replies }


appendReply : Reply -> Post -> Post
appendReply reply post =
    { post | replies = Connection.append Reply.getId reply post.replies }


groupsInclude : Group -> Post -> Bool
groupsInclude group post =
    List.filter (\g -> (Group.getId g) == (Group.getId group)) post.groups
        |> List.isEmpty
        |> not
