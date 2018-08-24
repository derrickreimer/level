module Repo exposing
    ( Repo, init
    , getGroup, getGroups, setGroup
    , getSpace, getSpaces, setSpace
    , getPost, getPosts, setPost
    , getSpaceUser, getSpaceUsers, setSpaceUser
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

@docs getPost, getPosts, setPost


# Space Users

@docs getSpaceUser, getSpaceUsers, setSpaceUser


# Bookmarks

@docs getBookmarks

-}

import Group exposing (Group)
import IdentityMap exposing (IdentityMap)
import Lazy exposing (Lazy(..))
import Post exposing (Post)
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
    , posts : IdentityMap Post.Record
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



-- POSTS


getPost : Repo -> Post -> Post.Record
getPost (Repo { posts }) post =
    IdentityMap.get posts (Post.getCachedData post)


getPosts : Repo -> List Post -> List Post.Record
getPosts (Repo { posts }) list =
    List.map Post.getCachedData list
        |> IdentityMap.getList posts


setPost : Repo -> Post -> Repo
setPost (Repo repo) post =
    Repo { repo | posts = IdentityMap.set repo.posts (Post.getCachedData post) }



-- BOOKMARKS


getBookmarks : Repo -> String -> Lazy (List Group)
getBookmarks repo id =
    NotLoaded
