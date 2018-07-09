module Connection
    exposing
        ( Connection
        , PageInfo
        , fragment
        , isEmpty
        , toList
        , map
        , decoder
        , get
        , update
        , prepend
        , append
        )

import GraphQL exposing (Fragment)
import Json.Decode as Decode exposing (Decoder, field, bool, maybe, string, list)
import Util


type alias PageInfo =
    { hasPreviousPage : Bool
    , hasNextPage : Bool
    , startCursor : Maybe String
    , endCursor : Maybe String
    }


type alias Id =
    String


type alias Node a =
    { a | id : Id }


type Connection a
    = Connection (List a) PageInfo


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
isEmpty (Connection nodes pageInfo) =
    pageInfo.startCursor
        == Nothing
        && pageInfo.endCursor
        == Nothing
        && (List.isEmpty nodes)


toList : Connection a -> List a
toList (Connection nodes _) =
    nodes



-- MAPPING


map : (a -> b) -> Connection a -> List b
map f (Connection nodes _) =
    List.map f nodes



-- DECODING


decoder : Decoder (Node a) -> Decoder (Connection (Node a))
decoder nodeDecoder =
    Decode.map2 Connection
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
get id (Connection nodes _) =
    Util.getById id nodes


update : Node a -> Connection (Node a) -> Connection (Node a)
update node (Connection nodes pageInfo) =
    let
        replacer a =
            if node.id == a.id then
                a
            else
                node

        newNodes =
            List.map replacer nodes
    in
        Connection newNodes pageInfo


prepend : Node a -> Connection (Node a) -> Connection (Node a)
prepend node (Connection nodes pageInfo) =
    let
        newNodes =
            if Util.memberById node nodes then
                nodes
            else
                node :: nodes
    in
        Connection newNodes pageInfo


append : Node a -> Connection (Node a) -> Connection (Node a)
append node (Connection nodes pageInfo) =
    let
        newNodes =
            if Util.memberById node nodes then
                nodes
            else
                List.append nodes [ node ]
    in
        Connection newNodes pageInfo
