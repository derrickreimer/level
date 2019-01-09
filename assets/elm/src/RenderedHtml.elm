module RenderedHtml exposing (node)

import Html exposing (Html)
import Html.Attributes exposing (property)
import Html.Events exposing (on)
import Json.Decode as Decode
import Json.Encode as Encode


type alias Config msg =
    { html : String
    , onInternalLinkClicked : String -> msg
    }


node : Config msg -> Html msg
node config =
    Html.node "rendered-html"
        [ property "content" (Encode.string config.html)
        , on "internalLinkClicked" <|
            Decode.map config.onInternalLinkClicked
                (Decode.at [ "detail", "pathname" ] Decode.string)
        ]
        []
