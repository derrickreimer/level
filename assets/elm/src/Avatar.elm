module Avatar exposing (Size(..), texitar)

import Html exposing (..)
import Html.Attributes exposing (..)


type Size
    = Small
    | Medium
    | Large


texitar : Size -> String -> Html msg
texitar size initials =
    div
        [ classList
            [ ( "texitar", True )
            , ( sizeClass size, True )
            ]
        ]
        [ text initials ]


sizeClass : Size -> String
sizeClass size =
    case size of
        Small ->
            ""

        Medium ->
            "texitar-md"

        Large ->
            "texitar-lg"
