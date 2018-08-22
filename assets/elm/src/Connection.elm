module Connection exposing (Connection, Subset, append, decoder, endCursor, first, fragment, get, hasNextPage, hasPreviousPage, head, isEmpty, isEmptyAndExpanded, isExpandable, last, map, prepend, prependConnection, remove, startCursor, toList, update)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, bool, field, list, maybe, string)
import ListHelpers exposing (getBy, memberBy, size, updateBy)


type alias PageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    , startCursor : Maybe String
    , endCursor : Maybe String
    }


type Connection a
    = Connection (Data a)


type alias Data a =
    { nodes : List a
    , pageInfo : PageInfo
    }


type alias Subset a =
    { nodes : List a
    , hasPreviousPage : Bool
    , hasNextPage : Bool
    }



-- GRAPHQL


fragment : String -> Fragment -> Fragment
fragment name nodeFragment =
    let
        body =
            String.join "\n"
                [ "fragment " ++ name ++ "Fields on " ++ name ++ " {"
                , "  edges {"
                , "    node {"
                , "      ..." ++ GraphQL.fragmentName nodeFragment
                , "    }"
                , "  }"
                , "  pageInfo {"
                , "    ...PageInfoFields"
                , "  }"
                , "}"
                ]

        pageInfo =
            GraphQL.toFragment
                """
                fragment PageInfoFields on PageInfo {
                  hasPreviousPage
                  hasNextPage
                  startCursor
                  endCursor
                }
                """
                []
    in
    GraphQL.toFragment body [ nodeFragment, pageInfo ]



-- LISTS


toList : Connection a -> List a
toList (Connection { nodes }) =
    nodes


map : (a -> b) -> Connection a -> List b
map f connection =
    List.map f (toList connection)


isEmpty : Connection a -> Bool
isEmpty connection =
    connection
        |> toList
        |> List.isEmpty


isExpandable : Connection a -> Bool
isExpandable (Connection { pageInfo }) =
    pageInfo.hasPreviousPage || pageInfo.hasNextPage


isEmptyAndExpanded : Connection a -> Bool
isEmptyAndExpanded connection =
    isEmpty connection && not (isExpandable connection)



-- PAGINATION


hasPreviousPage : Connection a -> Bool
hasPreviousPage (Connection { pageInfo }) =
    pageInfo.hasPreviousPage


hasNextPage : Connection a -> Bool
hasNextPage (Connection { pageInfo }) =
    pageInfo.hasNextPage


startCursor : Connection a -> Maybe String
startCursor (Connection { pageInfo }) =
    pageInfo.startCursor


endCursor : Connection a -> Maybe String
endCursor (Connection { pageInfo }) =
    pageInfo.endCursor



-- SUBSETS


head : Connection a -> Maybe a
head (Connection { nodes }) =
    List.head nodes


first : Int -> Connection a -> Subset a
first n (Connection { nodes, pageInfo }) =
    let
        subsetHasNextPage =
            size nodes > n || pageInfo.hasNextPage

        partialNodes =
            List.take n nodes
    in
    Subset partialNodes pageInfo.hasPreviousPage subsetHasNextPage


last : Int -> Connection a -> Subset a
last n (Connection { nodes, pageInfo }) =
    let
        subsetHasPreviousPage =
            size nodes > n || pageInfo.hasPreviousPage

        partialNodes =
            ListHelpers.takeLast n nodes
    in
    Subset partialNodes subsetHasPreviousPage pageInfo.hasNextPage



-- DECODING


decoder : Decoder a -> Decoder (Connection a)
decoder nodeDecoder =
    Decode.map Connection <|
        Decode.map2 Data
            (field "edges" (list (field "node" nodeDecoder)))
            (field "pageInfo" pageInfoDecoder)


pageInfoDecoder : Decoder PageInfo
pageInfoDecoder =
    Decode.map4 PageInfo
        (field "hasPreviousPage" bool)
        (field "hasNextPage" bool)
        (field "startCursor" (maybe string))
        (field "endCursor" (maybe string))



-- CRUD OPERATIONS


get : (a -> comparable) -> comparable -> Connection a -> Maybe a
get comparator comparable connection =
    getBy comparator comparable (toList connection)


update : (a -> comparable) -> a -> Connection a -> Connection a
update comparator node connection =
    let
        newNodes =
            updateBy comparator node (toList connection)
    in
    replaceNodes newNodes connection


prepend : (a -> comparable) -> a -> Connection a -> Connection a
prepend comparator node connection =
    let
        oldNodes =
            toList connection

        newNodes =
            if memberBy comparator node oldNodes then
                oldNodes

            else
                node :: oldNodes
    in
    replaceNodes newNodes connection


append : (a -> comparable) -> a -> Connection a -> Connection a
append comparator node connection =
    let
        oldNodes =
            toList connection

        newNodes =
            if memberBy comparator node oldNodes then
                oldNodes

            else
                List.append oldNodes [ node ]
    in
    replaceNodes newNodes connection


prependConnection : Connection a -> Connection a -> Connection a
prependConnection (Connection extension) (Connection original) =
    let
        nodes =
            extension.nodes ++ original.nodes

        pageInfo =
            PageInfo
                extension.pageInfo.hasPreviousPage
                original.pageInfo.hasNextPage
                extension.pageInfo.startCursor
                original.pageInfo.endCursor
    in
    Connection (Data nodes pageInfo)


remove : (a -> comparable) -> comparable -> Connection a -> Connection a
remove comparator comparable connection =
    let
        flippedReplaceNodes conn list =
            replaceNodes list conn
    in
    toList connection
        |> List.filter (\node -> not (comparator node == comparable))
        |> flippedReplaceNodes connection



-- INTERNAL


replaceNodes : List a -> Connection a -> Connection a
replaceNodes newNodes (Connection data) =
    Connection { data | nodes = newNodes }
