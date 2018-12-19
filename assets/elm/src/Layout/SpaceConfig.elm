module Layout.SpaceConfig exposing (SpaceConfig)

import Group exposing (Group)
import Route exposing (Route)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)


type alias SpaceConfig =
    { space : Space
    , spaceUser : SpaceUser
    , bookmarks : List Group
    , currentRoute : Maybe Route
    }
