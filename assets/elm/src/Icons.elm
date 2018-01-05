module Icons exposing (..)

import Material.Icons.Action
import Svg
import Color


privacyIcon : Color.Color -> Int -> Svg.Svg msg
privacyIcon =
    Material.Icons.Action.lock
