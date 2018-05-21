module Avatar exposing (Size(..), texitar, userAvatar)

import Html exposing (..)
import Html.Attributes exposing (..)
import Data.User exposing (User)


type Size
    = Small
    | Medium
    | Large


userAvatar : Size -> User -> Html msg
userAvatar size user =
    user.firstName
        |> String.left 1
        |> String.toUpper
        |> texitar size


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
