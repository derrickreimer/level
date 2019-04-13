module View.PresenceList exposing (view)

import Avatar
import Html exposing (..)
import Html.Attributes exposing (..)
import Id exposing (Id)
import Presence exposing (Presence, PresenceList)
import Repo exposing (Repo)
import Route
import Route.SpaceUser
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)


view : Repo -> Space -> PresenceList -> Html msg
view repo space list =
    let
        userIds =
            list
                |> List.filter Presence.isExpanded
                |> List.map Presence.getUserId

        spaceUsers =
            repo
                |> Repo.getSpaceUsersByUserIds (Space.id space) userIds
                |> List.sortBy SpaceUser.lastName
    in
    if List.isEmpty spaceUsers then
        div [ class "pb-4 text-md" ] [ text "There is nobody here." ]

    else
        div [ class "pb-4" ] <| List.map (itemView space) spaceUsers


itemView : Space -> SpaceUser -> Html msg
itemView space user =
    a
        [ Route.href <| Route.SpaceUser (Route.SpaceUser.init (Space.slug space) (SpaceUser.handle user))
        , class "flex items-center pr-4 mb-px no-underline text-dusty-blue-darker"
        ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Tiny user ]
        , div [ class "flex-grow text-md truncate" ] [ text <| SpaceUser.displayName user ]
        ]
