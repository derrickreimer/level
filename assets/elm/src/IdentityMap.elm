module IdentityMap exposing (IdentityMap, init, get, set, getList)

import Dict exposing (Dict)


type alias Id =
    String


type IdentityMap a
    = IdentityMap (Dict Id a)


init : IdentityMap a
init =
    IdentityMap Dict.empty


get : IdentityMap a -> (a -> Id) -> a -> a
get (IdentityMap dict) toId record =
    Dict.get (toId record) dict
        |> Maybe.withDefault record


set : IdentityMap a -> (a -> Id) -> a -> IdentityMap a
set (IdentityMap dict) toId record =
    IdentityMap <| Dict.insert (toId record) record dict


getList : IdentityMap a -> (a -> Id) -> List a -> List a
getList map toId list =
    List.map (get map toId) list
