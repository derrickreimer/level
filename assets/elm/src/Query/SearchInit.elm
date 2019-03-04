module Query.SearchInit exposing (Response, request)

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
    , groupIds : List Id
    , spaceUserIds : List Id
    , searchResults : List SearchResult
    , repo : Repo
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    , resolvedSearchResults : List ResolvedSearchResult
    }


document : Document
document =
    GraphQL.toDocument
        """
        query SearchInit(
          $spaceSlug: String!,
          $query: String!,
          $cursor: Timestamp
        ) {
          spaceUser(spaceSlug: $spaceSlug) {
            ...SpaceUserFields
            space {
              ...SpaceFields
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
        [ Group.fragment
        , SpaceUser.fragment
        , Space.fragment
        , SearchResult.fragment
        ]


variables : Params -> Maybe Encode.Value
variables params =
    Just <|
        Encode.object
            [ ( "spaceSlug", Encode.string (Route.Search.getSpaceSlug params) )
            , ( "query", Encode.string (Route.Search.getQuery params |> Maybe.withDefault "") )
            , ( "page", Encode.int (Route.Search.getPage params |> Maybe.withDefault 1) )
            ]


decoder : Decoder Data
decoder =
    Decode.at [ "data", "spaceUser" ] <|
        (Decode.succeed Data
            |> Pipeline.custom SpaceUser.decoder
            |> Pipeline.custom (Decode.field "space" Space.decoder)
            |> Pipeline.custom (Decode.at [ "space", "groups", "edges" ] (Decode.list (Decode.field "node" Group.decoder)))
            |> Pipeline.custom (Decode.at [ "space", "spaceUsers", "edges" ] (Decode.list (Decode.field "node" SpaceUser.decoder)))
            |> Pipeline.custom (Decode.at [ "space", "search" ] (Decode.list ResolvedSearchResult.decoder))
        )


addSearchResultsToRepo : List ResolvedSearchResult -> Repo -> Repo
addSearchResultsToRepo resolvedSearchResults repo =
    List.foldr ResolvedSearchResult.addToRepo repo resolvedSearchResults


buildResponse : ( Session, Data ) -> ( Session, Response )
buildResponse ( session, data ) =
    let
        repo =
            Repo.empty
                |> Repo.setSpaceUser data.viewer
                |> Repo.setSpace data.space
                |> Repo.setGroups data.groups
                |> Repo.setSpaceUsers data.spaceUsers
                |> addSearchResultsToRepo data.resolvedSearchResults

        resp =
            Response
                (SpaceUser.id data.viewer)
                (Space.id data.space)
                (List.map Group.id data.groups)
                (List.map SpaceUser.id data.spaceUsers)
                (List.map ResolvedSearchResult.unresolve data.resolvedSearchResults)
                repo
    in
    ( session, resp )


request : Params -> Session -> Task Session.Error ( Session, Response )
request params session =
    GraphQL.request document (variables params) decoder
        |> Session.request session
        |> Task.map buildResponse
