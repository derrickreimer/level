module Icons exposing (..)

import Material.Icons.Action
import Material.Icons.Communication
import Svg
import Color


privacyIcon : Color.Color -> Int -> Svg.Svg msg
privacyIcon =
    Material.Icons.Action.lock


commentIcon : Color.Color -> Int -> Svg.Svg msg
commentIcon =
    Material.Icons.Communication.comment
