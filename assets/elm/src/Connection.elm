module Connection exposing (Connection, isEmpty)

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
