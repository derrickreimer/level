module Avatar exposing (Size(..), texitar, avatar, personAvatar, thingAvatar)

import Html exposing (..)
import Html.Attributes exposing (..)


type Size
    = Tiny
    | Small
    | Medium
    | Large


type alias Person a =
    { a | firstName : String, lastName : String, avatarUrl : Maybe String }


type alias Thing a =
    { a | name : String, avatarUrl : Maybe String }



-- API


{-| A text-based avatar (to be used a placeholder when there does not exist
an uploaded avatar image).
-}
texitar : Size -> String -> Html msg
texitar size initials =
    div
        [ classList
            [ ( "avatar", True )
            , ( sizeClass size, True )
            ]
        ]
        [ text initials ]


{-| An image-based avatar.
-}
avatar : Size -> String -> Html msg
avatar size url =
    img
        [ src url
        , classList
            [ ( "avatar", True )
            , ( sizeClass size, True )
            ]
        ]
        []


{-| The avatar to display for a person.
-}
personAvatar : Size -> Person a -> Html msg
personAvatar size user =
    case user.avatarUrl of
        Just url ->
            avatar size url

        Nothing ->
            personTexitar size user


{-| The avatar to display for a thing with a `name` (like a space).
-}
thingAvatar : Size -> Thing a -> Html msg
thingAvatar size ({ name } as thing) =
    case thing.avatarUrl of
        Just url ->
            avatar size url

        Nothing ->
            texitar size (initial name)



-- INTERNAL


personTexitar : Size -> Person a -> Html msg
personTexitar size { firstName, lastName } =
    let
        text =
            case size of
                Tiny ->
                    initial firstName

                _ ->
                    initials [ firstName, lastName ]
    in
        texitar size text


initial : String -> String
initial name =
    name
        |> String.left 1
        |> String.toUpper


initials : List String -> String
initials words =
    words
        |> List.map initial
        |> String.join ""


sizeClass : Size -> String
sizeClass size =
    case size of
        Tiny ->
            "avatar-tiny"

        Small ->
            ""

        Medium ->
            "avatar-md"

        Large ->
            "avatar-lg"
