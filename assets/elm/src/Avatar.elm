module Avatar exposing (Config, Size(..), avatar, botAvatar, fromConfig, personAvatar, texitar, thingAvatar, uploader)

import File
import Html exposing (..)
import Html.Attributes exposing (..)


type Size
    = Tiny
    | Small
    | Medium
    | Large
    | XLarge


type alias Config =
    { size : Size
    , initials : String
    , avatarUrl : Maybe String
    }


type alias Person a =
    { a | firstName : String, lastName : String, avatarUrl : Maybe String }


type alias Thing a =
    { a | name : String, avatarUrl : Maybe String }


type alias Bot a =
    { a | displayName : String, avatarUrl : Maybe String }



-- DISPLAY


fromConfig : Config -> Html msg
fromConfig config =
    case config.avatarUrl of
        Just url ->
            avatar config.size url

        Nothing ->
            texitar config.size config.initials


{-| A text-based avatar (to be used a placeholder when there does not exist
an uploaded avatar image).
-}
texitar : Size -> String -> Html msg
texitar size body =
    div
        [ classList
            [ ( "avatar font-sans", True )
            , ( sizeClass size, True )
            ]
        ]
        [ text body ]


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


{-| The avatar to display for a thing with a `name` (like a space).
-}
botAvatar : Size -> Bot a -> Html msg
botAvatar size ({ displayName } as bot) =
    case bot.avatarUrl of
        Just url ->
            avatar size url

        Nothing ->
            texitar size (initial displayName)



-- FORM INPUT


uploader : String -> Maybe String -> msg -> Html msg
uploader nodeId maybeSrc changeMsg =
    case maybeSrc of
        Just avatarUrl ->
            label [ class "flex w-24 h-24 rounded-full cursor-pointer bg-grey-light" ]
                [ img [ src avatarUrl, class "w-full h-full rounded-full" ] []
                , File.input nodeId changeMsg [ class "invisible-file" ]
                ]

        Nothing ->
            label [ class "flex w-24 h-24 items-center text-center text-sm leading-tight text-dusty-blue border-2 rounded-full border-dashed cursor-pointer no-select" ]
                [ text "Upload an avatar..."
                , File.input nodeId changeMsg [ class "invisible-file" ]
                ]



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

        XLarge ->
            "avatar-xl"
