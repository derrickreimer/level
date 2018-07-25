module Repo
    exposing
        ( Repo
        , init
        , getGroup
        , getGroups
        , setGroup
        , getSpace
        , getSpaces
        , setSpace
        , getUser
        , getUsers
        , setUser
        )

import Data.Group exposing (Group)
import Data.Space as Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import IdentityMap exposing (IdentityMap)


type alias Repo =
    { groups : IdentityMap Group
    , users : IdentityMap SpaceUser
    , spaces : IdentityMap Space.Record
    }


init : Repo
init =
    Repo emptyMap emptyMap emptyMap


emptyMap : IdentityMap a
emptyMap =
    IdentityMap.init



-- GROUPS


getGroup : Repo -> Group -> Group
getGroup { groups } group =
    IdentityMap.get groups .id group


getGroups : Repo -> List Group -> List Group
getGroups { groups } list =
    IdentityMap.getList groups .id list


setGroup : Repo -> Group -> Repo
setGroup repo group =
    { repo | groups = IdentityMap.set repo.groups .id group }



-- SPACES


getSpace : Repo -> Space -> Space.Record
getSpace { spaces } space =
    IdentityMap.get spaces .id (Space.getCachedData space)


getSpaces : Repo -> List Space -> List Space.Record
getSpaces { spaces } list =
    List.map Space.getCachedData list
        |> IdentityMap.getList spaces .id


setSpace : Repo -> Space -> Repo
setSpace repo space =
    { repo | spaces = IdentityMap.set repo.spaces .id (Space.getCachedData space) }



-- USERS


getUser : Repo -> SpaceUser -> SpaceUser
getUser { users } user =
    IdentityMap.get users .id user


getUsers : Repo -> List SpaceUser -> List SpaceUser
getUsers { users } list =
    IdentityMap.getList users .id list


setUser : Repo -> SpaceUser -> Repo
setUser repo user =
    { repo | users = IdentityMap.set repo.users .id user }
