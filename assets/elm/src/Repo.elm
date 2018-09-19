module Repo exposing
    ( Repo, init
    , getGroup, getGroups, setGroup
    , getSpace, getSpaces, setSpace
    , getPost, setPost
    , getSpaceUser, getSpaceUsers, setSpaceUser, getSpaceUsersByUserId, getSpaceUserByUserId
    , getBookmarks
    )

{-| The Repo is the central repository for storing data.


# Definitions

@docs Repo, init


# Groups

@docs getGroup, getGroups, setGroup


# Spaces

@docs getSpace, getSpaces, setSpace


# Posts

@docs getPost, setPost


# Space Users

@docs getSpaceUser, getSpaceUsers, setSpaceUser, getSpaceUsersByUserId, getSpaceUserByUserId


# Bookmarks

@docs getBookmarks

-}

import Group exposing (Group)
import IdentityMap exposing (IdentityMap)
import Lazy exposing (Lazy(..))
import Post.Types
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)


{-| The data structure for storing data.
-}
type Repo
    = Repo Internal


type alias Internal =
    { groups : IdentityMap Group.Record
    , spaceUsers : IdentityMap SpaceUser.Record
    , spaces : IdentityMap Space.Record
    , posts : IdentityMap Post.Types.Data
    }


init : Repo
init =
    Repo
        (Internal
            IdentityMap.init
            IdentityMap.init
            IdentityMap.init
            IdentityMap.init
        )



-- GROUPS


getGroup : Repo -> Group -> Group.Record
getGroup (Repo { groups }) group =
    IdentityMap.get groups (Group.getCachedData group)


getGroups : Repo -> List Group -> List Group.Record
getGroups (Repo { groups }) list =
    List.map Group.getCachedData list
        |> IdentityMap.getList groups


setGroup : Repo -> Group -> Repo
setGroup (Repo repo) group =
    Repo { repo | groups = IdentityMap.set repo.groups (Group.getCachedData group) }



-- SPACES


getSpace : Repo -> Space -> Space.Record
getSpace (Repo { spaces }) space =
    IdentityMap.get spaces (Space.getCachedData space)


getSpaces : Repo -> List Space -> List Space.Record
getSpaces (Repo { spaces }) list =
    List.map Space.getCachedData list
        |> IdentityMap.getList spaces


setSpace : Repo -> Space -> Repo
setSpace (Repo repo) space =
    Repo { repo | spaces = IdentityMap.set repo.spaces (Space.getCachedData space) }



-- USERS


getSpaceUser : Repo -> SpaceUser -> SpaceUser.Record
getSpaceUser (Repo { spaceUsers }) user =
    IdentityMap.get spaceUsers (SpaceUser.getCachedData user)


getSpaceUsers : Repo -> List SpaceUser -> List SpaceUser.Record
getSpaceUsers (Repo { spaceUsers }) list =
    List.map SpaceUser.getCachedData list
        |> IdentityMap.getList spaceUsers


setSpaceUser : Repo -> SpaceUser -> Repo
setSpaceUser (Repo repo) user =
    Repo { repo | spaceUsers = IdentityMap.set repo.spaceUsers (SpaceUser.getCachedData user) }


getSpaceUserByUserId : Repo -> String -> Maybe SpaceUser.Record
getSpaceUserByUserId (Repo { spaceUsers }) userId =
    spaceUsers
        |> IdentityMap.filter (\record -> record.userId == userId)
        |> List.head


getSpaceUsersByUserId : Repo -> List String -> List SpaceUser.Record
getSpaceUsersByUserId (Repo repo) userIds =
    repo.spaceUsers
        |> IdentityMap.filter (\record -> List.any (\id -> id == record.userId) userIds)



-- POSTS


getPost : Repo -> Post.Types.Data -> Post.Types.Data
getPost (Repo { posts }) data =
    IdentityMap.get posts data


setPost : Repo -> Post.Types.Data -> Repo
setPost (Repo repo) data =
    Repo { repo | posts = IdentityMap.set repo.posts data }



-- BOOKMARKS


getBookmarks : Repo -> String -> Lazy (List Group)
getBookmarks repo id =
    NotLoaded
