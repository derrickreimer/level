module Clipboard exposing (button)

import Html exposing (Attribute, Html)
import Html.Attributes exposing (attribute, property)
import Json.Encode as Encode


{-| Generates a "click-to-copy" button.
-}
button : String -> String -> List (Attribute msg) -> Html msg
button text clipboardText attrs =
    let
        attrsWithProps =
            attrs
                ++ [ property "text" (Encode.string text)
                   , attribute "data-clipboard-text" clipboardText
                   ]
    in
    Html.node "clipboard-button" attrsWithProps []
