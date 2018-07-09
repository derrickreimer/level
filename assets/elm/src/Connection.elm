module Connection
    exposing
        ( Connection
        , fragment
        , isEmpty
        , isExpandable
        , isEmptyAndExpanded
        , toList
        , map
        , takeLast
        , decoder
        , get
        , update
        , prepend
        , append
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


type alias PartialPageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    }


type alias Id =
    String


type alias Node a =
    { a | id : Id }


type Connection a
    = FullConnection (List a) PageInfo
    | PartialConnection (List a) PartialPageInfo


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
    in
        GraphQL.fragment body [ nodeFragment, pageInfoFragment ]


pageInfoFragment : Fragment
pageInfoFragment =
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



-- BASICS


isEmpty : Connection a -> Bool
isEmpty connection =
    connection
        |> toList
        |> List.isEmpty


isExpandable : Connection a -> Bool
isExpandable connection =
    let
        ( nodes, hasPreviousPage, hasNextPage ) =
            toPartialData connection
    in
        hasPreviousPage || hasNextPage


isEmptyAndExpanded : Connection a -> Bool
isEmptyAndExpanded connection =
    isEmpty connection && not (isExpandable connection)


toList : Connection a -> List a
toList connection =
    case connection of
        FullConnection nodes _ ->
            nodes

        PartialConnection nodes _ ->
            nodes



-- LIST OPERATIONS


map : (a -> b) -> Connection a -> List b
map f connection =
    List.map f (toList connection)


takeLast : Int -> Connection a -> Connection a
takeLast n connection =
    let
        ( nodes, hasPreviousPage, hasNextPage ) =
            toPartialData connection

        partialHasPreviousPage =
            size nodes > n || hasPreviousPage

        partialNodes =
            ListHelpers.takeLast n nodes
    in
        PartialConnection partialNodes
            (PartialPageInfo partialHasPreviousPage hasNextPage)


toPartialData : Connection a -> ( List a, Bool, Bool )
toPartialData connection =
    case connection of
        FullConnection nodes { hasPreviousPage, hasNextPage } ->
            ( nodes, hasPreviousPage, hasNextPage )

        PartialConnection nodes { hasPreviousPage, hasNextPage } ->
            ( nodes, hasPreviousPage, hasNextPage )



-- DECODING


decoder : Decoder (Node a) -> Decoder (Connection (Node a))
decoder nodeDecoder =
    Decode.map2 FullConnection
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


replaceNodes : List a -> Connection a -> Connection a
replaceNodes newNodes connection =
    case connection of
        FullConnection _ pageInfo ->
            FullConnection newNodes pageInfo

        PartialConnection _ pageInfo ->
            PartialConnection newNodes pageInfo
