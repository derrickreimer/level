module IdentityMap exposing (IdentityMap, Node, filter, get, getList, init, set)

import Dict exposing (Dict)


type alias Id =
    String


type IdentityMap a
    = IdentityMap (Dict Id a)


type alias Node a =
    { a | id : Id, fetchedAt : Int }


init : IdentityMap (Node a)
init =
    Dict.empty
        |> IdentityMap


get : IdentityMap (Node a) -> Node a -> Node a
get (IdentityMap dict) record =
    case Dict.get record.id dict of
        Just savedRecord ->
            if savedRecord.fetchedAt < record.fetchedAt then
                record

            else
                savedRecord

        Nothing ->
            record


set : IdentityMap (Node a) -> Node a -> IdentityMap (Node a)
set (IdentityMap dict) record =
    let
        newDict =
            case Dict.get record.id dict of
                Just savedRecord ->
                    if savedRecord.fetchedAt < record.fetchedAt then
                        Dict.insert record.id record dict

                    else
                        dict

                Nothing ->
                    Dict.insert record.id record dict
    in
    IdentityMap newDict


getList : IdentityMap (Node a) -> List (Node a) -> List (Node a)
getList imap list =
    List.map (get imap) list


filter : (Node a -> Bool) -> IdentityMap (Node a) -> List (Node a)
filter fn (IdentityMap dict) =
    dict
        |> Dict.values
        |> List.filter fn
