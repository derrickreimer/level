module Query.PostInit exposing (Params, Response, task)

import Date exposing (Date)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task exposing (Task)
import Component.Post
import Data.Post exposing (Post)
import GraphQL exposing (Document)
import Session exposing (Session)


type alias Params =
    { spaceId : String
    , postId : String
    }


type alias Response =
    { post : Component.Post.Model
    , now : Date
    }


document : Document
document =
    GraphQL.document
        """
        query PostInit(
          $spaceId: ID!
          $postId: ID!
        ) {
          space(id: $spaceId) {
            post(id: $postId) {
              ...PostFields
            }
          }
        }
        """
        [ Data.Post.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
        Encode.object
            [ ( "spaceId", Encode.string params.spaceId )
            , ( "postId", Encode.string params.postId )
            ]


decoder : Date -> Decoder Response
decoder now =
    Decode.at [ "data", "space", "post" ] <|
        Decode.map2 Response
            (Component.Post.decoder Component.Post.FullPage)
            (Decode.succeed now)


request : Date -> Params -> Session -> Http.Request Response
request now params =
    GraphQL.request document (variables params) (decoder now)


task : String -> String -> Session -> Date -> Task Session.Error ( Session, Response )
task spaceId postId session now =
    Params spaceId postId
        |> request now
        |> Session.request session
