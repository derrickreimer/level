module SpaceUserLists exposing (SpaceUserLists, init, resolveList, setList)

import Dict exposing (Dict)
import Id exposing (Id)
import Repo exposing (Repo)
import SpaceUser exposing (SpaceUser)


type SpaceUserLists
    = SpaceUserLists Internal


type alias Internal =
    Dict Id (List Id)



-- API


init : SpaceUserLists
init =
    SpaceUserLists Dict.empty


setList : Id -> List Id -> SpaceUserLists -> SpaceUserLists
setList spaceId ids (SpaceUserLists dict) =
    SpaceUserLists (Dict.insert spaceId ids dict)


resolveList : Repo -> Id -> SpaceUserLists -> List SpaceUser
resolveList repo spaceId (SpaceUserLists dict) =
    case Dict.get spaceId dict of
        Just ids ->
            Repo.getSpaceUsers ids repo

        Nothing ->
            []
