module Connection exposing (Connection, isEmpty, toList, map)

import Data.PageInfo exposing (PageInfo)


type alias Connection a b =
    { a | pageInfo : PageInfo, nodes : List b }



-- BASICS


isEmpty : Connection a b -> Bool
isEmpty { pageInfo, nodes } =
    pageInfo.startCursor
        == Nothing
        && pageInfo.endCursor
        == Nothing
        && (List.isEmpty nodes)


toList : Connection a b -> List b
toList { nodes } =
    nodes



-- MAPPING


map : (b -> c) -> Connection a b -> List c
map f { nodes } =
    List.map f nodes
