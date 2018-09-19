module NewRepo exposing (NewRepo, empty)

import Dict exposing (Dict)
import Group exposing (Group)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)


type NewRepo
    = NewRepo InternalData


type alias InternalData =
    { spaces : Dict String Space
    , spaceUsers : Dict String SpaceUser
    , groups : Dict String Group
    }


empty : NewRepo
empty =
    NewRepo (InternalData Dict.empty Dict.empty Dict.empty)


setSpace : NewRepo -> Space -> NewRepo
setSpace (NewRepo data) space =
    NewRepo { data | spaces = Dict.insert (Space.id space) space data.spaces }


setSpaceUser : NewRepo -> SpaceUser -> NewRepo
setSpaceUser (NewRepo data) spaceUser =
    NewRepo { data | spaceUsers = Dict.insert (SpaceUser.id spaceUser) spaceUser data.spaceUsers }


setGroup : NewRepo -> Group -> NewRepo
setGroup (NewRepo data) group =
    NewRepo { data | groups = Dict.insert (Group.id group) group data.groups }
