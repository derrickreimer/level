module Connection exposing (Connection, isEmpty)

import Data.PageInfo exposing (PageInfo)


type alias Connection a b =
    { a | pageInfo : PageInfo, edges : List b }



-- BASICS


isEmpty : Connection a b -> Bool
isEmpty { pageInfo, edges } =
    pageInfo.startCursor
        == Nothing
        && pageInfo.endCursor
        == Nothing
        && (List.isEmpty edges)
