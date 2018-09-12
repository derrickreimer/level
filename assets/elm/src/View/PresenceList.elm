module View.PresenceList exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Presence exposing (Presence, PresenceList)
import Repo exposing (Repo)


view : Repo -> PresenceList -> Html msg
view repo list =
    -- TODO: implement this
    text ""
