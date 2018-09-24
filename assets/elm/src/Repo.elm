module Repo exposing (Repo, empty, getGroup, getGroups, getPost, getReplies, getReply, getSpace, getSpaceUser, getSpaceUserByUserId, getSpaceUsers, getSpaceUsersByUserId, getSpaces, getUser, setGroup, setGroups, setPost, setPosts, setReplies, setReply, setSpace, setSpaceUser, setSpaceUsers, setSpaces, setUser, union)

import Dict exposing (Dict)
import Group exposing (Group)
import Id exposing (Id)
import Post exposing (Post)
import Reply exposing (Reply)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import User exposing (User)


type Repo
    = Repo InternalData


type alias InternalData =
    { users : Dict Id User
    , spaces : Dict Id Space
    , spaceUsers : Dict Id SpaceUser
    , groups : Dict Id Group
    , posts : Dict Id Post
    , replies : Dict Id Reply
    }


empty : Repo
empty =
    Repo (InternalData Dict.empty Dict.empty Dict.empty Dict.empty Dict.empty Dict.empty)


getUser : String -> Repo -> Maybe User
getUser id (Repo data) =
    Dict.get id data.users


setUser : User -> Repo -> Repo
setUser user (Repo data) =
    Repo { data | users = Dict.insert (User.id user) user data.users }


getSpace : String -> Repo -> Maybe Space
getSpace id (Repo data) =
    Dict.get id data.spaces


getSpaces : List String -> Repo -> List Space
getSpaces ids repo =
    List.filterMap (\id -> getSpace id repo) ids


setSpace : Space -> Repo -> Repo
setSpace space (Repo data) =
    Repo { data | spaces = Dict.insert (Space.id space) space data.spaces }


setSpaces : List Space -> Repo -> Repo
setSpaces spaces repo =
    List.foldr setSpace repo spaces


getSpaceUser : String -> Repo -> Maybe SpaceUser
getSpaceUser id (Repo data) =
    Dict.get id data.spaceUsers


getSpaceUsers : List String -> Repo -> List SpaceUser
getSpaceUsers ids repo =
    List.filterMap (\id -> getSpaceUser id repo) ids


getSpaceUserByUserId : String -> Repo -> Maybe SpaceUser
getSpaceUserByUserId userId (Repo data) =
    data.spaceUsers
        |> Dict.values
        |> List.filter (\su -> SpaceUser.userId su == userId)
        |> List.head


getSpaceUsersByUserId : List String -> Repo -> List SpaceUser
getSpaceUsersByUserId userIds (Repo data) =
    data.spaceUsers
        |> Dict.values
        |> List.filter (\su -> List.member (SpaceUser.userId su) userIds)


setSpaceUser : SpaceUser -> Repo -> Repo
setSpaceUser spaceUser (Repo data) =
    Repo { data | spaceUsers = Dict.insert (SpaceUser.id spaceUser) spaceUser data.spaceUsers }


setSpaceUsers : List SpaceUser -> Repo -> Repo
setSpaceUsers spaceUsers repo =
    List.foldr setSpaceUser repo spaceUsers


getGroup : String -> Repo -> Maybe Group
getGroup id (Repo data) =
    Dict.get id data.groups


getGroups : List String -> Repo -> List Group
getGroups ids repo =
    List.filterMap (\id -> getGroup id repo) ids


setGroup : Group -> Repo -> Repo
setGroup group (Repo data) =
    Repo { data | groups = Dict.insert (Group.id group) group data.groups }


setGroups : List Group -> Repo -> Repo
setGroups groups repo =
    List.foldr setGroup repo groups


getPost : String -> Repo -> Maybe Post
getPost id (Repo data) =
    Dict.get id data.posts


setPost : Post -> Repo -> Repo
setPost post (Repo data) =
    Repo { data | posts = Dict.insert (Post.id post) post data.posts }


setPosts : List Post -> Repo -> Repo
setPosts posts repo =
    List.foldr setPost repo posts


getReply : String -> Repo -> Maybe Reply
getReply id (Repo data) =
    Dict.get id data.replies


getReplies : List String -> Repo -> List Reply
getReplies ids repo =
    List.filterMap (\id -> getReply id repo) ids


setReply : Reply -> Repo -> Repo
setReply reply (Repo data) =
    Repo { data | replies = Dict.insert (Reply.id reply) reply data.replies }


setReplies : List Reply -> Repo -> Repo
setReplies replies repo =
    List.foldr setReply repo replies


union : Repo -> Repo -> Repo
union (Repo newer) (Repo older) =
    Repo <|
        InternalData
            (Dict.union newer.users older.users)
            (Dict.union newer.spaces older.spaces)
            (Dict.union newer.spaceUsers older.spaceUsers)
            (Dict.union newer.groups older.groups)
            (Dict.union newer.posts older.posts)
            (Dict.union newer.replies older.replies)
