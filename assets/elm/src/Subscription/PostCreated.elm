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


payload : String -> Payload
payload id =
    Payload query (Just (variables (Params id)))


query : String
query =
    """
      subscription PostCreated(
        $id: ID!
      ) {
        postCreated(spaceUserId: $id) {
          post {
            id
            body
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
