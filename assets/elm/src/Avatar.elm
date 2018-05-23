module Avatar exposing (Size(..), texitar, personAvatar)

import Html exposing (..)
import Html.Attributes exposing (..)


type Size
    = Small
    | Medium
    | Large


type alias Person a =
    { a | firstName : String, lastName : String }


initial : String -> String
initial name =
    name
        |> String.left 1
        |> String.toUpper


personAvatar : Size -> Person a -> Html msg
personAvatar size user =
    let
        firstInitial =
            initial user.firstName
                |> String.left 1
                |> String.toUpper

        lastInitial =
            initial user.lastName
    in
        (firstInitial ++ lastInitial)
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
