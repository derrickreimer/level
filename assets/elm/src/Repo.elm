module Repo exposing (Repo, init, getGroup, getGroups, setGroup)

import Data.Group exposing (Group)
import IdentityMap exposing (IdentityMap)


type alias Repo =
    { groups : IdentityMap Group
    }


init : Repo
init =
    Repo emptyMap


emptyMap : IdentityMap a
emptyMap =
    IdentityMap.init


getGroup : Repo -> Group -> Group
getGroup { groups } group =
    IdentityMap.get groups .id group


getGroups : Repo -> List Group -> List Group
getGroups { groups } list =
    IdentityMap.mapList groups .id list


setGroup : Repo -> Group -> Repo
setGroup repo group =
    { repo | groups = IdentityMap.set repo.groups .id group }
