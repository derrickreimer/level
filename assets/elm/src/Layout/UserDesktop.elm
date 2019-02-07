module Layout.UserDesktop exposing (Config, layout, rightSidebar)

import Avatar exposing (personAvatar, thingAvatar)
import Flash exposing (Flash)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Json.Decode as Decode
import Lazy exposing (Lazy(..))
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Apps
import Route.Group
import Route.Groups
import Route.Help
import Route.Inbox
import Route.NewPost
import Route.Posts
import Route.Settings
import Route.SpaceUsers
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import User exposing (User)
import View.Helpers exposing (viewIf, viewUnless)



-- TYPES


type alias Config msg =
    { globals : Globals
    , viewer : User
    , onNoOp : msg
    , onToggleKeyboardCommands : msg
    }



-- API


layout : Config msg -> List (Html msg) -> Html msg
layout config children =
    div [ class "font-sans font-antialised" ]
        [ spacesSidebar config
        , fullSidebar config
        , div [ class "ml-64 lg:ml-64 lg:mr-64" ] children
        , div [ class "fixed pin-t pin-r z-50", id "headway" ] []
        , Flash.view config.globals.flash
        , viewIf config.globals.showKeyboardCommands (keyboardCommandReference config)
        ]


rightSidebar : List (Html msg) -> Html msg
rightSidebar children =
    div
        [ classList
            [ ( "fixed pin-r pin-t mt-2 py-2 pl-6 min-h-half", True )
            , ( "hidden lg:block md:w-48 lg:w-56", True )
            ]
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
            case config.globals.spaceIds of
                Loaded spaceIds ->
                    config.globals.repo
                        |> Repo.getSpaces spaceIds
                        |> List.sortBy Space.name

                NotLoaded ->
                    []

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
    div [ class "fixed h-full z-40" ]
        [ div [ class "p-3" ]
            [ a
                [ Route.href Route.Home
                , class "flex items-center mb-4 justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
                ]
                [ Icons.home homeToggle ]
            ]
        , div [ class "px-3 absolute overflow-y-scroll", style "top" "65px", style "bottom" "70px" ]
            [ div [ class "mb-4" ] <| List.map (spaceLink config) spaces
            , a
                [ Route.href Route.NewSpace
                , class "flex items-center mb-3 justify-center w-9 h-9 rounded-full bg-grey-light hover:bg-grey transition-bg"
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
    a
        [ Route.href (Route.Root (Space.slug space))
        , classList
            [ ( "block mb-1 no-underline hover:opacity-100", True )
            , ( "opacity-50", True )
            ]
        ]
        [ Space.avatar Avatar.Small space ]


fullSidebar : Config msg -> Html msg
fullSidebar config =
    div
        [ classList
            [ ( "fixed w-48 h-full min-h-screen z-30", True )
            ]
        , style "left" "4.5rem"
        ]
        [ div [ class "absolute w-full", style "bottom" "0.75rem", style "left" "0.75rem" ]
            [ a [ Route.href Route.UserSettings, class "flex items-center p-2 no-underline border-turquoise hover:bg-grey rounded transition-bg" ]
                [ div [ class "flex-no-shrink" ] [ User.avatar Avatar.Small config.viewer ]
                , div [ class "flex-grow ml-2 text-sm text-dusty-blue-darker leading-normal overflow-hidden" ]
                    [ div [] [ text "Signed in as" ]
                    , div [ class "font-bold truncate" ] [ text (User.displayName config.viewer) ]
                    ]
                ]
            ]
        ]
