module Icons exposing (..)

import Material.Icons.Action
import Material.Icons.Communication
import Material.Icons.Hardware
import Svg
import Color


privacyIcon : Color.Color -> Int -> Svg.Svg msg
privacyIcon =
    Material.Icons.Action.lock


commentIcon : Color.Color -> Int -> Svg.Svg msg
commentIcon =
    Material.Icons.Communication.comment


settingsIcon : Color.Color -> Int -> Svg.Svg msg
settingsIcon =
    Material.Icons.Action.settings


leftArrowIcon : Color.Color -> Int -> Svg.Svg msg
leftArrowIcon =
    Material.Icons.Hardware.keyboard_arrow_left
