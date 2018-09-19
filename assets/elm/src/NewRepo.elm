module NewRepo exposing (NewRepo, empty, setGroup, setGroups, setPost, setPosts, setReplies, setReply, setSpace, setSpaceUser)

import Dict exposing (Dict)
import Group exposing (Group)
import Post exposing (Post)
import Reply exposing (Reply)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)


type NewRepo
    = NewRepo InternalData


type alias InternalData =
    { spaces : Dict String Space
    , spaceUsers : Dict String SpaceUser
    , groups : Dict String Group
    , posts : Dict String Post
    , replies : Dict String Reply
    }


empty : NewRepo
empty =
    NewRepo (InternalData Dict.empty Dict.empty Dict.empty Dict.empty Dict.empty)


setSpace : Space -> NewRepo -> NewRepo
setSpace space (NewRepo data) =
    NewRepo { data | spaces = Dict.insert (Space.id space) space data.spaces }


setSpaceUser : SpaceUser -> NewRepo -> NewRepo
setSpaceUser spaceUser (NewRepo data) =
    NewRepo { data | spaceUsers = Dict.insert (SpaceUser.id spaceUser) spaceUser data.spaceUsers }


setGroup : Group -> NewRepo -> NewRepo
setGroup group (NewRepo data) =
    NewRepo { data | groups = Dict.insert (Group.id group) group data.groups }


setGroups : List Group -> NewRepo -> NewRepo
setGroups groups repo =
    List.foldr setGroup repo groups


setPost : Post -> NewRepo -> NewRepo
setPost post (NewRepo data) =
    NewRepo { data | posts = Dict.insert (Post.id post) post data.posts }


setPosts : List Post -> NewRepo -> NewRepo
setPosts posts repo =
    List.foldr setPost repo posts


setReply : Reply -> NewRepo -> NewRepo
setReply reply (NewRepo data) =
    NewRepo { data | replies = Dict.insert (Reply.id reply) reply data.replies }


setReplies : List Reply -> NewRepo -> NewRepo
setReplies replies repo =
    List.foldr setReply repo replies
