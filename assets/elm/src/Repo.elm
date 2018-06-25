module Repo
    exposing
        ( Repo
        , init
        , getGroup
        , getGroups
        , setGroup
        , getUser
        , getUsers
        , setUser
        )

import Data.Group exposing (Group)
import Data.SpaceUser exposing (SpaceUser)
import IdentityMap exposing (IdentityMap)


type alias Repo =
    { groups : IdentityMap Group
    , users : IdentityMap SpaceUser
    }


init : Repo
init =
    Repo emptyMap emptyMap


emptyMap : IdentityMap a
emptyMap =
    IdentityMap.init


getGroup : Repo -> Group -> Group
getGroup { groups } group =
    IdentityMap.get groups .id group


getGroups : Repo -> List Group -> List Group
getGroups { groups } list =
    IdentityMap.getList groups .id list


setGroup : Repo -> Group -> Repo
setGroup repo group =
    { repo | groups = IdentityMap.set repo.groups .id group }


getUser : Repo -> SpaceUser -> SpaceUser
getUser { users } user =
    IdentityMap.get users .id user


getUsers : Repo -> List SpaceUser -> List SpaceUser
getUsers { users } list =
    IdentityMap.getList users .id list


setUser : Repo -> SpaceUser -> Repo
setUser repo user =
    { repo | users = IdentityMap.set repo.users .id user }
