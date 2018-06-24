module Repo exposing (Repo, init, setGroup)

import Data.Group exposing (Group)
import IdentityMap exposing (IdentityMap, init)


type alias Repo =
    { groups : IdentityMap Group
    }


init : Repo
init =
    Repo IdentityMap.init


setGroup : Group -> Repo -> Repo
setGroup group ({ groups } as repo) =
    { repo | groups = IdentityMap.set .id groups group }
