module Connection exposing (Connection, Subset, append, decoder, diff, endCursor, filterMap, first, fragment, get, hasNextPage, hasPreviousPage, head, isEmpty, isEmptyAndExpanded, isExpandable, last, map, mapList, prepend, prependConnection, remove, selectNext, selectPrev, selected, startCursor, toList, update)

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, bool, field, list, maybe, string)
import ListHelpers exposing (getBy, memberBy, updateBy)
import Set
import Vendor.SelectList as SelectList exposing (SelectList)


type alias PageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    , startCursor : Maybe String
    , endCursor : Maybe String
    }


type Connection a
    = Connection (Data a)


type alias Data a =
    { nodes : Nodes a
    , pageInfo : PageInfo
    }


type alias Subset a =
    { nodes : Nodes a
    , hasPreviousPage : Bool
    , hasNextPage : Bool
    }


type Nodes a
    = NonEmpty (SelectList a)
    | Empty



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



-- TRANFORMATIONS


map : (a -> b) -> Connection a -> Connection b
map f (Connection data) =
    Connection (Data (mapNodes f data.nodes) data.pageInfo)


filterMap : (a -> Maybe b) -> Connection a -> Connection b
filterMap f (Connection data) =
    let
        unfilteredNodes =
            nodesToList data.nodes

        filteredNodes =
            List.filterMap f unfilteredNodes
    in
    Connection (Data (listToNodes filteredNodes) data.pageInfo)



-- LISTS


toList : Connection a -> List a
toList (Connection { nodes }) =
    nodesToList nodes


mapList : (a -> b) -> Connection a -> List b
mapList f connection =
    List.map f (toList connection)


isEmpty : Connection a -> Bool
isEmpty (Connection data) =
    data.nodes == Empty


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
    nodes
        |> nodesToList
        |> List.head


first : Int -> Connection a -> Subset a
first n (Connection { nodes, pageInfo }) =
    let
        nodeList =
            nodesToList nodes

        subsetHasNextPage =
            List.length nodeList > n || pageInfo.hasNextPage

        partialNodes =
            List.take n nodeList
                |> listToNodes
    in
    Subset partialNodes pageInfo.hasPreviousPage subsetHasNextPage


last : Int -> Connection a -> Subset a
last n (Connection { nodes, pageInfo }) =
    let
        nodeList =
            nodesToList nodes

        subsetHasPreviousPage =
            List.length nodeList > n || pageInfo.hasPreviousPage

        partialNodes =
            ListHelpers.takeLast n nodeList
                |> listToNodes
    in
    Subset partialNodes subsetHasPreviousPage pageInfo.hasNextPage



-- DECODING


decoder : Decoder a -> Decoder (Connection a)
decoder nodeDecoder =
    Decode.map Connection <|
        Decode.map2 Data
            (field "edges" (Decode.map listToNodes (list (field "node" nodeDecoder))))
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
update comparator newNode (Connection data) =
    let
        replacer currentNode =
            if comparator currentNode == comparator newNode then
                newNode

            else
                currentNode

        newNodes =
            case data.nodes of
                Empty ->
                    Empty

                NonEmpty slist ->
                    NonEmpty (SelectList.map replacer slist)
    in
    Connection { data | nodes = newNodes }


prepend : (a -> comparable) -> a -> Connection a -> Connection a
prepend comparator node (Connection data) =
    let
        newNodes =
            case data.nodes of
                Empty ->
                    listToNodes [ node ]

                NonEmpty slist ->
                    if memberBy comparator node (SelectList.toList slist) then
                        NonEmpty slist

                    else
                        NonEmpty (SelectList.prepend [ node ] slist)
    in
    Connection { data | nodes = newNodes }


append : (a -> comparable) -> a -> Connection a -> Connection a
append comparator node (Connection data) =
    let
        newNodes =
            case data.nodes of
                Empty ->
                    listToNodes [ node ]

                NonEmpty slist ->
                    if memberBy comparator node (SelectList.toList slist) then
                        NonEmpty slist

                    else
                        NonEmpty (SelectList.append [ node ] slist)
    in
    Connection { data | nodes = newNodes }


prependConnection : Connection a -> Connection a -> Connection a
prependConnection (Connection extension) (Connection original) =
    case original.nodes of
        Empty ->
            Connection extension

        NonEmpty originalNodes ->
            let
                nodes =
                    NonEmpty <|
                        SelectList.prepend (nodesToList extension.nodes) originalNodes

                pageInfo =
                    PageInfo
                        extension.pageInfo.hasPreviousPage
                        original.pageInfo.hasNextPage
                        extension.pageInfo.startCursor
                        original.pageInfo.endCursor
            in
            Connection (Data nodes pageInfo)


remove : (a -> comparable) -> comparable -> Connection a -> Connection a
remove comparator comparable (Connection data) =
    let
        newNodes =
            case data.nodes of
                Empty ->
                    Empty

                NonEmpty slist ->
                    let
                        before =
                            SelectList.before slist

                        after =
                            SelectList.after slist

                        currentNode =
                            SelectList.selected slist
                    in
                    if comparator currentNode == comparable then
                        case ( List.reverse before, after ) of
                            ( [], [] ) ->
                                Empty

                            ( hd :: tl, [] ) ->
                                NonEmpty (SelectList.fromLists (List.reverse tl) hd [])

                            ( _, hd :: tl ) ->
                                NonEmpty (SelectList.fromLists before hd tl)

                    else
                        let
                            newBefore =
                                List.filter (\node -> not (comparator node == comparable)) before

                            newAfter =
                                List.filter (\node -> not (comparator node == comparable)) after
                        in
                        NonEmpty (SelectList.fromLists newBefore currentNode newAfter)
    in
    Connection { data | nodes = newNodes }


diff : (a -> comparable) -> Connection a -> Connection a -> ( List a, List a )
diff comparator newConn oldConn =
    let
        newNodes =
            toList newConn

        oldNodes =
            toList oldConn

        newComparables =
            newNodes
                |> List.map comparator
                |> Set.fromList

        oldComparables =
            oldNodes
                |> List.map comparator
                |> Set.fromList

        commonComparables =
            Set.intersect newComparables oldComparables

        addedComparables =
            commonComparables
                |> Set.diff newComparables
                |> Set.toList

        removedComparables =
            commonComparables
                |> Set.diff oldComparables
                |> Set.toList

        addedNodes =
            newNodes
                |> List.filter (\node -> List.member (comparator node) addedComparables)

        removedNodes =
            oldNodes
                |> List.filter (\node -> List.member (comparator node) removedComparables)
    in
    ( addedNodes, removedNodes )


selected : Connection a -> Maybe a
selected (Connection data) =
    case data.nodes of
        Empty ->
            Nothing

        NonEmpty slist ->
            Just (SelectList.selected slist)


selectPrev : Connection a -> Connection a
selectPrev (Connection data) =
    let
        newNodes =
            case data.nodes of
                Empty ->
                    Empty

                NonEmpty slist ->
                    case List.reverse (SelectList.before slist) of
                        [] ->
                            NonEmpty slist

                        newSelected :: newBeforeReversed ->
                            NonEmpty <|
                                SelectList.fromLists
                                    (List.reverse newBeforeReversed)
                                    newSelected
                                    (SelectList.selected slist :: SelectList.after slist)
    in
    Connection { data | nodes = newNodes }


selectNext : Connection a -> Connection a
selectNext (Connection data) =
    let
        newNodes =
            case data.nodes of
                Empty ->
                    Empty

                NonEmpty slist ->
                    case SelectList.after slist of
                        [] ->
                            NonEmpty slist

                        newSelected :: newAfter ->
                            NonEmpty <|
                                SelectList.fromLists
                                    (SelectList.before slist ++ [ SelectList.selected slist ])
                                    newSelected
                                    newAfter
    in
    Connection { data | nodes = newNodes }



-- INTERNAL


replaceNodes : Nodes a -> Connection a -> Connection a
replaceNodes newNodes (Connection data) =
    Connection { data | nodes = newNodes }


listToNodes : List a -> Nodes a
listToNodes list =
    case list of
        [] ->
            Empty

        hd :: tl ->
            NonEmpty (SelectList.fromLists [] hd tl)


nodesToList : Nodes a -> List a
nodesToList nodes =
    case nodes of
        Empty ->
            []

        NonEmpty slist ->
            SelectList.toList slist


mapNodes : (a -> b) -> Nodes a -> Nodes b
mapNodes fn nodes =
    case nodes of
        Empty ->
            Empty

        NonEmpty slist ->
            NonEmpty (SelectList.map fn slist)
