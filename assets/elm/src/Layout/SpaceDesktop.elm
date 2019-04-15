module Layout.SpaceDesktop exposing (Config, layout, rightSidebar)

import Avatar exposing (personAvatar, thingAvatar)
import Flash exposing (Flash)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import InboxStateFilter
import Json.Decode as Decode
import Layout.SpaceSidebar as SpaceSidebar
import Lazy exposing (Lazy(..))
import Post exposing (Post)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Apps
import Route.Group
import Route.Groups
import Route.Help
import Route.NewPost
import Route.Posts
import Route.Settings
import Route.SpaceUsers
import Set exposing (Set)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import User exposing (User)
import View.Helpers exposing (viewIf, viewUnless)



-- TYPES


type alias Config msg =
    { globals : Globals
    , space : Space
    , spaceUser : SpaceUser
    , onNoOp : msg
    , onToggleKeyboardCommands : msg
    , onPageClicked : msg
    }



-- API


layout : Config msg -> List (Html msg) -> Html msg
layout config children =
    div [ class "font-sans font-antialised h-screen", onClick config.onPageClicked ]
        [ spacesSidebar config
        , div
            [ classList
                [ ( "pl-16", True )
                , ( "xl:px-24", not config.globals.showNotifications )
                , ( "xl:pr-24", config.globals.showNotifications )
                ]
            ]
            [ div
                [ classList
                    [ ( "fixed w-48 xxl:w-64 h-full min-h-screen z-30", True )
                    ]
                ]
                [ SpaceSidebar.view
                    { globals = config.globals
                    , space = config.space
                    , spaceUser = config.spaceUser
                    }
                ]
            , div
                [ classList
                    [ ( "ml-48 mr-16 relative", True )
                    , ( "xl:mr-48", not config.globals.showNotifications )
                    , ( "xl:mr-64", config.globals.showNotifications )
                    ]
                ]
                children
            ]
        , div [ class "fixed pin-b pin-r z-50", id "headway" ] []
        , Flash.view config.globals.flash
        , viewIf config.globals.showKeyboardCommands (keyboardCommandReference config)
        ]


rightSidebar : List (Html msg) -> Html msg
rightSidebar children =
    div
        [ classList
            [ ( "fixed pin-t pin-b py-4 w-48", True )
            , ( "hidden xl:block", True )
            ]
        , style "right" "60px"
        ]
        children


keyboardCommandReference : Config msg -> Html msg
keyboardCommandReference config =
    div
        [ class "absolute pin z-50"
        , style "background-color" "rgba(0,0,0,0.5)"
        , onClick config.onToggleKeyboardCommands
        ]
        [ div
            [ class "absolute overflow-y-auto pin-t pin-r pin-b w-80 bg-white p-6 shadow-lg"
            , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed config.onNoOp))
            ]
            [ h2 [ class "pb-3 text-base text-dusty-blue-darkest" ] [ text "Keyboard Commands" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Actions" ]
            , keyboardCommandItem "Shortcuts" [ "?" ]
            , keyboardCommandItem "Search" [ "/" ]
            , keyboardCommandItem "Compose a Post" [ "C" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Navigation" ]
            , keyboardCommandItem "Next / Previous Post" [ "J", "K" ]
            , keyboardCommandItem "Go to Inbox" [ "i" ]
            , keyboardCommandItem "Go to Feed" [ "F" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Posts" ]
            , keyboardCommandItem "Dismiss from Inbox" [ "E" ]
            , keyboardCommandItem "Move to Inbox" [ "⌘", "E" ]
            , keyboardCommandItem "Resolve" [ "Y" ]
            , keyboardCommandItem "Reply" [ "R" ]
            , keyboardCommandItem "Send" [ "⌘", "enter" ]
            , keyboardCommandItem "Send + Resolve" [ "⌘", "shift", "enter" ]
            , keyboardCommandItem "Close Reply Editor" [ "esc" ]
            ]
        ]


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )


keyboardCommandItem : String -> List String -> Html msg
keyboardCommandItem name keys =
    div [ class "mb-1 flex text-sm" ]
        [ div [ class "flex-no-shrink w-40" ] [ text name ]
        , div [ class "flex flex-grow text-xs font-bold text-grey-light", style "line-height" "18px" ] (List.map keyView keys)
        ]


keyboardCommandJumpItem : String -> String -> Html msg
keyboardCommandJumpItem name key =
    div [ class "mb-1 flex text-sm" ]
        [ div [ class "flex-no-shrink w-40" ] [ text name ]
        , div [ class "flex flex-grow text-xs font-bold text-grey-light", style "line-height" "18px" ]
            [ keyView "G"
            , div [ class "mr-1 text-dusty-blue" ] [ text "+" ]
            , keyView key
            ]
        ]


keyView : String -> Html msg
keyView value =
    div [ class "mr-1 px-1 bg-dusty-blue-dark text-center rounded", style "min-width" "18px" ] [ text value ]



-- PRIVATE


spacesSidebar : Config msg -> Html msg
spacesSidebar config =
    let
        spaces =
            config.globals.repo
                |> Repo.getAllSpaces
                |> List.sortBy Space.name

        homeToggle =
            if config.globals.currentRoute == Just Route.Home then
                Icons.On

            else
                Icons.Off

        newSpaceToggle =
            if config.globals.currentRoute == Just Route.NewSpace then
                Icons.On

            else
                Icons.Off
    in
    div [ class "fixed h-full z-40 bg-grey-light" ]
        [ div [ class "p-3 pt-2" ]
            [ a
                [ Route.href Route.Home
                , class "flex items-center mb-4 justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
                ]
                [ Icons.home homeToggle ]
            ]
        , div [ class "px-3 absolute overflow-y-scroll", style "top" "60px", style "bottom" "70px" ]
            [ viewIf (List.length spaces > 1) <|
                div [ class "mb-4" ] <|
                    List.map (spaceLink config) spaces
            , a
                [ Route.href Route.NewSpace
                , class "flex items-center mb-3 justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
                ]
                [ Icons.plus newSpaceToggle ]
            ]
        , div [ class "p-3" ]
            [ a
                [ class "tooltip tooltip-right absolute pin-b flex items-center mb-5 justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
                , href "/logout"
                , rel "tooltip"
                , title "Sign out"
                , attribute "data-tooltip" "Sign out"
                ]
                [ Icons.logOut ]
            ]
        ]


spaceLink : Config msg -> Space -> Html msg
spaceLink config space =
    let
        avatar =
            if Space.isDemo space then
                div [ class "relative inline-block" ]
                    [ Space.avatar Avatar.Small space
                    , div [ class "absolute px-1 pin-b -mb-2 shadow-white rounded-full bg-green text-xxs font-bold text-white uppercase" ] [ text "Demo" ]
                    ]

            else
                Space.avatar Avatar.Small space
    in
    a
        [ Route.href (Route.Root (Space.slug space))
        , classList
            [ ( "block mb-1 no-underline hover:opacity-100", True )
            , ( "opacity-50", True )
            ]
        ]
        [ avatar ]
