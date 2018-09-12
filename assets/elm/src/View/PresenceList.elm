module View.PresenceList exposing (view)

import Avatar exposing (personAvatar)
import Html exposing (..)
import Html.Attributes exposing (..)
import Presence exposing (Presence, PresenceList)
import Repo exposing (Repo)
import SpaceUser
import View.Helpers exposing (displayName)


view : Repo -> PresenceList -> Html msg
view repo list =
    let
        userIds =
            Presence.getUserIds list

        spaceUsers =
            userIds
                |> Repo.getSpaceUsersByUserId repo
                |> List.sortBy .lastName
    in
    if List.isEmpty spaceUsers then
        div [ class "pb-4 text-sm" ] [ text "There is nobody here." ]

    else
        div [ class "pb-4" ] <| List.map itemView spaceUsers


itemView : SpaceUser.Record -> Html msg
itemView data =
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny data ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| displayName data ]
        ]
