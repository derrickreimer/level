module Clipboard exposing (button, onCopy, onCopyFailed)

import Html exposing (Attribute, Html)
import Html.Attributes exposing (attribute, property)
import Html.Events exposing (on)
import Json.Decode as Decode
import Json.Encode as Encode


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


onCopy : msg -> Attribute msg
onCopy msg =
    on "copy" (Decode.succeed msg)


onCopyFailed : msg -> Attribute msg
onCopyFailed msg =
    on "copyFailed" (Decode.succeed msg)
