module IdentityMap exposing (IdentityMap, init, get, set, mapList)

import Dict exposing (Dict)


type alias Id =
    String


type alias IdentityMap a =
    Dict Id a


init : IdentityMap a
init =
    Dict.empty


get : (a -> Id) -> IdentityMap a -> a -> a
get toId map record =
    Dict.get (toId record) map
        |> Maybe.withDefault record


set : (a -> Id) -> IdentityMap a -> a -> IdentityMap a
set toId map record =
    Dict.insert (toId record) record map


mapList : (a -> Id) -> IdentityMap a -> List a -> List a
mapList toId map list =
    List.map (get toId map) list
