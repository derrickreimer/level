module RenderedHtml exposing (node)

import Html exposing (Html)
import Html.Attributes exposing (property)
import Json.Encode as Encode


node : String -> Html msg
node html =
    Html.node "rendered-html"
        [ property "content" (Encode.string html) ]
        []
