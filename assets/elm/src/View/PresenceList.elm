module View.PresenceList exposing (view)

import Avatar
import Html exposing (..)
import Html.Attributes exposing (..)
import Presence exposing (Presence, PresenceList)
import Repo exposing (Repo)
import SpaceUser exposing (SpaceUser)


view : Repo -> PresenceList -> Html msg
view repo list =
    let
        spaceUsers =
            repo
                |> Repo.getSpaceUsersByUserId (Presence.getUserIds list)
                |> List.sortBy SpaceUser.lastName
    in
    if List.isEmpty spaceUsers then
        div [ class "pb-4 text-sm" ] [ text "There is nobody here." ]

    else
        div [ class "pb-4" ] <| List.map itemView spaceUsers


itemView : SpaceUser -> Html msg
itemView spaceUser =
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Tiny spaceUser ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| SpaceUser.displayName spaceUser ]
        ]
