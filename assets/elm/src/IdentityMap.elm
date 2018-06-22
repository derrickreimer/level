module IdentityMap exposing (IdentityMap, init, get, set)

import Dict exposing (Dict)


type alias Id =
    String


type alias Record a =
    { a | id : Id }


type alias IdentityMap a =
    Dict Id (Record a)


init : IdentityMap a
init =
    Dict.empty


get : Record a -> IdentityMap a -> Record a
get ({ id } as record) map =
    Dict.get id map
        |> Maybe.withDefault record


set : Record a -> IdentityMap a -> IdentityMap a
set ({ id } as record) map =
    Dict.insert id record map
