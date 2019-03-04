module Query.SearchResults exposing (Response, request, variables)

import GraphQL exposing (Document)
import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Repo exposing (Repo)
import ResolvedSearchResult exposing (ResolvedSearchResult)
import Route.Search exposing (Params)
import SearchResult exposing (SearchResult)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import Time exposing (Posix)


type alias Response =
    { results : List SearchResult
    , repo : Repo
    }


type alias Data =
    { resolvedResults : List ResolvedSearchResult
    }


document : Document
document =
    GraphQL.toDocument
        """
        query SearchResults(
          $spaceSlug: String!,
          $query: String!,
          $cursor: Timestamp
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            space {
              search(
                query: $query,
                cursor: $cursor
              ) {
                ...SearchResultFields
              }
            }
          }
        }
        """
        [ SearchResult.fragment
        ]


variables : Params -> Maybe Posix -> Maybe Encode.Value
variables params maybeCursor =
    let
        vars =
            [ ( "spaceSlug", Encode.string (Route.Search.getSpaceSlug params) )
            , ( "query", Encode.string (Route.Search.getQuery params |> Maybe.withDefault "") )
            ]

        varsWithCursor =
            case maybeCursor of
                Just cursor ->
                    ( "cursor", Encode.int (Time.posixToMillis cursor) ) :: vars

                Nothing ->
                    vars
    in
    Just <|
        Encode.object varsWithCursor


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        Decode.map Data
            (Decode.at [ "space", "search" ] (Decode.list ResolvedSearchResult.decoder))


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> ResolvedSearchResult.addManyToRepo data.resolvedResults

        resp =
            Response
                (List.map ResolvedSearchResult.unresolve data.resolvedResults)
                repo
    in
    ( session, resp )


request : Maybe Encode.Value -> Session -> Task Session.Error ( Session, Response )
request maybeVariables session =
    GraphQL.request document maybeVariables decoder
        |> Session.request session
        |> Task.map buildResponse
