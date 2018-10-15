module Query.SearchInit exposing (Response, request)

import Connection exposing (Connection)
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


type alias Response =
    { viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , searchResults : Connection SearchResult
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , resolvedSearchResults : Connection ResolvedSearchResult
    }


document : Document
document =
    GraphQL.toDocument
        """
        query SearchInit(
          $spaceSlug: String!,
          $query: String!,
          $first: Int,
          $after: Cursor
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
              search(
                query: $query,
                first: $first,
                after: $after
              ) {
                ...SearchConnectionFields
              }
            }
            bookmarks {
              ...GroupFields
            }
          }
        }
        """
        [ Group.fragment
        , SpaceUser.fragment
        , Space.fragment
        , Connection.fragment "SearchConnection" SearchResult.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string (Route.Search.getSpaceSlug params) )
            , ( "query", Encode.string (Route.Search.getQuery params |> Maybe.withDefault "") )
            , ( "first", Encode.int 20 )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        (Decode.succeed Data
            |> Pipeline.custom SpaceUser.decoder
            |> Pipeline.custom (Decode.field "space" Space.decoder)
            |> Pipeline.custom (Decode.field "bookmarks" (Decode.list Group.decoder))
            |> Pipeline.custom (Decode.at [ "space", "search" ] (Connection.decoder ResolvedSearchResult.decoder))
        )


addSearchResultsToRepo : Connection ResolvedSearchResult -> Repo -> Repo
addSearchResultsToRepo resolvedSearchResults repo =
    List.foldr ResolvedSearchResult.addToRepo repo (Connection.toList resolvedSearchResults)


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.bookmarks
                |> addSearchResultsToRepo data.resolvedSearchResults

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.bookmarks)
                (Connection.map ResolvedSearchResult.unresolve data.resolvedSearchResults)
                repo
    in
    ( session, resp )


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    GraphQL.request document (variables params) decoder
        |> Session.request session
        |> Task.map buildResponse
