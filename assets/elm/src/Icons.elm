module Icons exposing (..)

import Material.Icons.Action as Action
import Material.Icons.Content as Content
import Material.Icons.Hardware as Hardware
import Material.Icons.Navigation as Navigation
import Material.Icons.Social as Social
import Svg
import Color


privacyIcon : Color.Color -> Int -> Svg.Svg msg
privacyIcon =
    Action.lock


convoIcon : Color.Color -> Int -> Svg.Svg msg
convoIcon =
    Content.send


settingsIcon : Color.Color -> Int -> Svg.Svg msg
settingsIcon =
    Action.settings


leftArrowIcon : Color.Color -> Int -> Svg.Svg msg
leftArrowIcon =
    Hardware.keyboard_arrow_left


closeIcon : Color.Color -> Int -> Svg.Svg msg
closeIcon =
    Navigation.close


peopleIcon : Color.Color -> Int -> Svg.Svg msg
peopleIcon =
    Social.people
