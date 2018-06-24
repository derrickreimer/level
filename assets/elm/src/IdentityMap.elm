module IdentityMap exposing (IdentityMap, init, get, set, mapList)

import Dict exposing (Dict)


type alias Id =
    String


type alias IdentityMap a =
    Dict Id a


init : IdentityMap a
init =
    Dict.empty


get : IdentityMap a -> (a -> Id) -> a -> a
get map toId record =
    Dict.get (toId record) map
        |> Maybe.withDefault record


set : IdentityMap a -> (a -> Id) -> a -> IdentityMap a
set map toId record =
    Dict.insert (toId record) record map


mapList : IdentityMap a -> (a -> Id) -> List a -> List a
mapList map toId list =
    List.map (get map toId) list
