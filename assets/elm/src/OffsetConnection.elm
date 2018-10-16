module OffsetConnection exposing (OffsetConnection, decoder, filterMap, hasNextPage, hasPreviousPage, isEmpty, isEmptyAndExpanded, map, toList)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, bool, field, list, maybe, string)
import ListHelpers exposing (getBy, memberBy, updateBy)
import Set


type alias PageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    }


type OffsetConnection a
    = OffsetConnection (Data a)


type alias Data a =
    { nodes : List a
    , pageInfo : PageInfo
    }



-- DECODER


decoder : Decoder a -> Decoder (OffsetConnection a)
decoder nodeDecoder =
    Decode.map OffsetConnection <|
        Decode.map2 Data
            (field "nodes" (list nodeDecoder))
            (field "pageInfo" pageInfoDecoder)


pageInfoDecoder : Decoder PageInfo
pageInfoDecoder =
    Decode.map2 PageInfo
        (field "hasPreviousPage" bool)
        (field "hasNextPage" bool)



-- TRANFORMATIONS


map : (a -> b) -> OffsetConnection a -> OffsetConnection b
map f (OffsetConnection data) =
    OffsetConnection (Data (List.map f data.nodes) data.pageInfo)


filterMap : (a -> Maybe b) -> OffsetConnection a -> OffsetConnection b
filterMap f (OffsetConnection data) =
    OffsetConnection (Data (List.filterMap f data.nodes) data.pageInfo)



-- LISTS


toList : OffsetConnection a -> List a
toList (OffsetConnection { nodes }) =
    nodes


isEmpty : OffsetConnection a -> Bool
isEmpty connection =
    connection
        |> toList
        |> List.isEmpty


isExpandable : OffsetConnection a -> Bool
isExpandable (OffsetConnection { pageInfo }) =
    pageInfo.hasPreviousPage || pageInfo.hasNextPage


isEmptyAndExpanded : OffsetConnection a -> Bool
isEmptyAndExpanded connection =
    isEmpty connection && not (isExpandable connection)



-- PAGINATION


hasPreviousPage : OffsetConnection a -> Bool
hasPreviousPage (OffsetConnection { pageInfo }) =
    pageInfo.hasPreviousPage


hasNextPage : OffsetConnection a -> Bool
hasNextPage (OffsetConnection { pageInfo }) =
    pageInfo.hasNextPage
