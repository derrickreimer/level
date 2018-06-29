module Subscription.PostCreated exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Data.Post exposing (Post, postDecoder)
import Socket exposing (Payload)


type alias Params =
    { id : String
    }


type alias Data =
    { post : Post
    }


clientId : String -> String
clientId id =
    "post_created_" ++ id


payload : String -> Payload
payload id =
    Payload (clientId id) query (Just <| variables <| Params id)


query : String
query =
    """
      subscription PostCreated(
        $id: ID!
      ) {
        postCreated(groupId: $id) {
          post {
            id
            body
            bodyHtml
            postedAt
            author {
              id
              firstName
              lastName
              role
            }
            groups {
              id
              name
            }
            replies(last: 10) {
              edges {
                node {
                  id
                  body
                  bodyHtml
                  postedAt
                  author {
                    id
                    firstName
                    lastName
                    role
                  }
                }
              }
              pageInfo {
                hasPreviousPage
                hasNextPage
                startCursor
                endCursor
              }
            }
          }
        }
      }
    """


variables : Params -> Encode.Value
variables params =
    Encode.object
        [ ( "id", Encode.string params.id )
        ]


decoder : Decode.Decoder Data
decoder =
    Decode.at [ "data", "postCreated" ] <|
        (Pipeline.decode Data
            |> Pipeline.custom (Decode.at [ "post" ] postDecoder)
        )
