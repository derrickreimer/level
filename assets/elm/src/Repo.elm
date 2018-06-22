module Repo exposing (Repo, init)

import Data.Group exposing (Group)
import IdentityMap exposing (IdentityMap, init)


type alias Repo =
    { groups : IdentityMap Group
    }


init : Repo
init =
    Repo IdentityMap.init
