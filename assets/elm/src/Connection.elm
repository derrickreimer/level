module Connection
    exposing
        ( Connection
        , Subset
        , fragment
        , toList
        , map
        , isEmpty
        , isExpandable
        , isEmptyAndExpanded
        , hasPreviousPage
        , hasNextPage
        , startCursor
        , endCursor
        , last
        , decoder
        , get
        , update
        , prepend
        , append
        , prependConnection
        )

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, field, bool, maybe, string, list)
import ListHelpers exposing (getById, memberById, updateById, size)


type alias PageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    , startCursor : Maybe String
    , endCursor : Maybe String
    }


type alias Node a =
    { a | id : String }


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
                , "      ..." ++ (GraphQL.fragmentName nodeFragment)
                , "    }"
                , "  }"
                , "  pageInfo {"
                , "    ...PageInfoFields"
                , "  }"
                , "}"
                ]

        pageInfo =
            GraphQL.fragment
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
        GraphQL.fragment body [ nodeFragment, pageInfo ]



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


last : Int -> Connection a -> Subset a
last n (Connection { nodes, pageInfo }) =
    let
        hasPreviousPage =
            size nodes > n || pageInfo.hasPreviousPage

        partialNodes =
            ListHelpers.takeLast n nodes
    in
        Subset partialNodes hasPreviousPage pageInfo.hasNextPage



-- DECODING


decoder : Decoder (Node a) -> Decoder (Connection (Node a))
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


get : String -> Connection (Node a) -> Maybe (Node a)
get id connection =
    getById id (toList connection)


update : Node a -> Connection (Node a) -> Connection (Node a)
update node connection =
    let
        newNodes =
            updateById node (toList connection)
    in
        replaceNodes newNodes connection


prepend : Node a -> Connection (Node a) -> Connection (Node a)
prepend node connection =
    let
        oldNodes =
            toList connection

        newNodes =
            if memberById node oldNodes then
                oldNodes
            else
                node :: oldNodes
    in
        replaceNodes newNodes connection


append : Node a -> Connection (Node a) -> Connection (Node a)
append node connection =
    let
        oldNodes =
            toList connection

        newNodes =
            if memberById node oldNodes then
                oldNodes
            else
                List.append oldNodes [ node ]
    in
        replaceNodes newNodes connection


prependConnection : Connection (Node a) -> Connection (Node a) -> Connection (Node a)
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



-- INTERNAL


replaceNodes : List a -> Connection a -> Connection a
replaceNodes newNodes (Connection data) =
    Connection { data | nodes = newNodes }
