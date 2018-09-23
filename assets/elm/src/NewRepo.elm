module NewRepo exposing (NewRepo, empty, getGroup, getGroups, getPost, getReplies, getReply, getSpace, getSpaceUser, getSpaceUserByUserId, getSpaceUsers, getSpaceUsersByUserId, setGroup, setGroups, setPost, setPosts, setReplies, setReply, setSpace, setSpaceUser, setSpaceUsers, union)

import Dict exposing (Dict)
import Group exposing (Group)
import Id exposing (Id)
import Post exposing (Post)
import Reply exposing (Reply)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)


type NewRepo
    = NewRepo InternalData


type alias InternalData =
    { spaces : Dict Id Space
    , spaceUsers : Dict Id SpaceUser
    , groups : Dict Id Group
    , posts : Dict Id Post
    , replies : Dict Id Reply
    }


empty : NewRepo
empty =
    NewRepo (InternalData Dict.empty Dict.empty Dict.empty Dict.empty Dict.empty)


getSpace : String -> NewRepo -> Maybe Space
getSpace id (NewRepo data) =
    Dict.get id data.spaces


setSpace : Space -> NewRepo -> NewRepo
setSpace space (NewRepo data) =
    NewRepo { data | spaces = Dict.insert (Space.id space) space data.spaces }


getSpaceUser : String -> NewRepo -> Maybe SpaceUser
getSpaceUser id (NewRepo data) =
    Dict.get id data.spaceUsers


getSpaceUsers : List String -> NewRepo -> List SpaceUser
getSpaceUsers ids repo =
    List.filterMap (\id -> getSpaceUser id repo) ids


getSpaceUserByUserId : String -> NewRepo -> Maybe SpaceUser
getSpaceUserByUserId userId (NewRepo data) =
    data.spaceUsers
        |> Dict.values
        |> List.filter (\su -> SpaceUser.userId su == userId)
        |> List.head


getSpaceUsersByUserId : List String -> NewRepo -> List SpaceUser
getSpaceUsersByUserId userIds (NewRepo data) =
    data.spaceUsers
        |> Dict.values
        |> List.filter (\su -> List.member (SpaceUser.userId su) userIds)


setSpaceUser : SpaceUser -> NewRepo -> NewRepo
setSpaceUser spaceUser (NewRepo data) =
    NewRepo { data | spaceUsers = Dict.insert (SpaceUser.id spaceUser) spaceUser data.spaceUsers }


setSpaceUsers : List SpaceUser -> NewRepo -> NewRepo
setSpaceUsers spaceUsers repo =
    List.foldr setSpaceUser repo spaceUsers


getGroup : String -> NewRepo -> Maybe Group
getGroup id (NewRepo data) =
    Dict.get id data.groups


getGroups : List String -> NewRepo -> List Group
getGroups ids repo =
    List.filterMap (\id -> getGroup id repo) ids


setGroup : Group -> NewRepo -> NewRepo
setGroup group (NewRepo data) =
    NewRepo { data | groups = Dict.insert (Group.id group) group data.groups }


setGroups : List Group -> NewRepo -> NewRepo
setGroups groups repo =
    List.foldr setGroup repo groups


getPost : String -> NewRepo -> Maybe Post
getPost id (NewRepo data) =
    Dict.get id data.posts


setPost : Post -> NewRepo -> NewRepo
setPost post (NewRepo data) =
    NewRepo { data | posts = Dict.insert (Post.id post) post data.posts }


setPosts : List Post -> NewRepo -> NewRepo
setPosts posts repo =
    List.foldr setPost repo posts


getReply : String -> NewRepo -> Maybe Reply
getReply id (NewRepo data) =
    Dict.get id data.replies


getReplies : List String -> NewRepo -> List Reply
getReplies ids repo =
    List.filterMap (\id -> getReply id repo) ids


setReply : Reply -> NewRepo -> NewRepo
setReply reply (NewRepo data) =
    NewRepo { data | replies = Dict.insert (Reply.id reply) reply data.replies }


setReplies : List Reply -> NewRepo -> NewRepo
setReplies replies repo =
    List.foldr setReply repo replies


union : NewRepo -> NewRepo -> NewRepo
union (NewRepo newer) (NewRepo older) =
    NewRepo <|
        InternalData
            (Dict.union newer.spaces older.spaces)
            (Dict.union newer.spaceUsers older.spaceUsers)
            (Dict.union newer.groups older.groups)
            (Dict.union newer.posts older.posts)
            (Dict.union newer.replies older.replies)
