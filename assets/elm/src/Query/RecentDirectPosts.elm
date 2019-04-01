module Query.RecentDirectPosts exposing (Response, request, variables)

import Connection exposing (Connection)
import GraphQL exposing (Document)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Json.Encode as Encode
import Post exposing (Post)
import Reply exposing (Reply)
import Repo exposing (Repo)
import ResolvedPost exposing (ResolvedPost)
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)


type alias Response =
    { resolvedPosts : Connection ResolvedPost
    , repo : Repo
    }


type alias Data =
    { resolvedPosts : Connection ResolvedPost
    }


document : Document
document =
    GraphQL.toDocument
        """
        query RecentDirectPosts {
          posts(
            first: 100
            filter: {
              privacy: DIRECT
            }
          ) {
            ...PostConnectionFields
          }
        }
        """
        [ Connection.fragment "PostConnection" Post.fragment
        ]


variables : Maybe Encode.Value
variables =
    Nothing


decoder : Decoder Data
decoder =
    Decode.at [ "data", "posts" ] <|
        Decode.map Data
            (Connection.decoder ResolvedPost.decoder)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> ResolvedPost.addManyToRepo (Connection.toList data.resolvedPosts)

        resp =
            Response
                data.resolvedPosts
                repo
    in
    ( session, resp )


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    GraphQL.request document maybeVariables decoder
        |> Session.request session
        |> Task.map buildResponse
