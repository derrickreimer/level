module ResolvedSpace exposing (ResolvedSpace, addManyToRepo, addToRepo, decoder, resolve, unresolve)

import Group exposing (Group)
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, list)
import Repo exposing (Repo)
import ResolvedAuthor exposing (ResolvedAuthor)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)


type alias ResolvedSpace =
    { space : Space
    , groups : List Group
    , spaceUsers : List SpaceUser
    }


decoder : Decoder ResolvedSpace
decoder =
    Decode.map3 ResolvedSpace
        Space.decoder
        (Decode.at [ "groups", "edges" ] (list (field "node" Group.decoder)))
        (Decode.at [ "spaceUsers", "edges" ] (list (field "node" SpaceUser.decoder)))


addToRepo : ResolvedSpace -> Repo -> Repo
addToRepo resolvedSpace repo =
    repo
        |> Repo.setSpace resolvedSpace.space
        |> Repo.setGroups resolvedSpace.groups
        |> Repo.setSpaceUsers resolvedSpace.spaceUsers


addManyToRepo : List ResolvedSpace -> Repo -> Repo
addManyToRepo resolvedSpaces repo =
    List.foldr addToRepo repo resolvedSpaces


resolve : Repo -> Id -> Maybe ResolvedSpace
resolve repo spaceId =
    case Repo.getSpace spaceId repo of
        Just space ->
            Maybe.map3 ResolvedSpace
                (Just space)
                (Just <| List.filterMap (\groupId -> Repo.getGroup groupId repo) (Space.groupIds space))
                (Just <| List.filterMap (\spaceUserId -> Repo.getSpaceUser spaceUserId repo) (Space.spaceUserIds space))

        Nothing ->
            Nothing


unresolve : ResolvedSpace -> Id
unresolve resolvedSpace =
    Space.id resolvedSpace.space
