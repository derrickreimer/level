module Data.Post exposing (Post, fragment, decoder)

import Date exposing (Date)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Data.Group exposing (Group, groupDecoder)
import Data.PageInfo
import Data.Reply exposing (ReplyConnection, replyConnectionDecoder)
import Data.SpaceUser exposing (SpaceUser, spaceUserDecoder)
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


decoder : Decode.Decoder Post
decoder =
    Pipeline.decode Post
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "body" Decode.string
        |> Pipeline.required "bodyHtml" Decode.string
        |> Pipeline.required "author" spaceUserDecoder
        |> Pipeline.required "groups" (Decode.list groupDecoder)
        |> Pipeline.required "postedAt" dateDecoder
        |> Pipeline.required "replies" replyConnectionDecoder
