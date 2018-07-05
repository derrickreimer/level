module Data.Post exposing (Post, fragment, decoder, appendReply)

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, list, string)
import Json.Decode.Pipeline as Pipeline
import Data.Group exposing (Group)
import Data.PageInfo
import Data.Reply exposing (Reply)
import Data.ReplyConnection exposing (ReplyConnection)
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
    , replies : ReplyConnection
    }


fragment : Fragment
fragment =
    GraphQL.fragment
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
          replies(last: 10) {
            edges {
              node {
                ...ReplyFields
              }
            }
            pageInfo {
              ...PageInfoFields
            }
          }
        }
        """
        [ Data.SpaceUser.fragment
        , Data.Group.fragment
        , Data.Reply.fragment
        , Data.PageInfo.fragment
        ]



-- DECODERS


decoder : Decoder Post
decoder =
    Pipeline.decode Post
        |> Pipeline.required "id" string
        |> Pipeline.required "body" string
        |> Pipeline.required "bodyHtml" string
        |> Pipeline.required "author" Data.SpaceUser.decoder
        |> Pipeline.required "groups" (list Data.Group.decoder)
        |> Pipeline.required "postedAt" dateDecoder
        |> Pipeline.required "replies" Data.ReplyConnection.decoder



-- CRUD


appendReply : Reply -> Post -> Post
appendReply reply post =
    { post | replies = Data.ReplyConnection.append reply post.replies }
