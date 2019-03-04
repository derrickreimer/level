module Element exposing (dropdown)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode


dropdown : msg -> List (Html msg) -> Html msg
dropdown toNoOp children =
    div
        [ class "relative"
        , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed toNoOp))
        ]
        children



-- PRIVATE


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )
