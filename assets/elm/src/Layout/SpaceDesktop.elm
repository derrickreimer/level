module Layout.SpaceDesktop exposing (Config, layout, rightSidebar)

import Avatar exposing (personAvatar, thingAvatar)
import Flash exposing (Flash)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Lazy exposing (Lazy(..))
import Route exposing (Route)
import Route.Group
import Route.Groups
import Route.Help
import Route.Inbox
import Route.Posts
import Route.Settings
import Route.SpaceUsers
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import User exposing (User)
import View.Helpers exposing (viewIf)



-- TYPES


type alias Config =
    { space : Space
    , spaceUser : SpaceUser
    , bookmarks : List Group
    , currentRoute : Maybe Route
    , flash : Flash
    , showKeyboardCommands : Bool
    }



-- API


layout : Config -> List (Html msg) -> Html msg
layout config children =
    div [ class "font-sans font-antialised" ]
        [ fullSidebar config
        , div [ class "ml-48 lg:ml-56 md:mr-48 lg:mr-56" ] children
        , div [ class "fixed pin-t pin-r z-50", id "headway" ] []
        , Flash.view config.flash
        , viewIf config.showKeyboardCommands keyboardCommandReference
        ]


rightSidebar : List (Html msg) -> Html msg
rightSidebar children =
    div
        [ classList
            [ ( "fixed pin-t pin-r mt-3 py-2 pl-6 min-h-half", True )
            , ( "hidden md:block md:w-48 lg:w-56", True )
            ]
        ]
        children


keyboardCommandReference : Html msg
keyboardCommandReference =
    div [ class "fixed pin z-50", style "background-color" "rgba(0,0,0,0.5)" ]
        [ div [ class "absolute overflow-y-auto pin-t pin-r pin-b w-80 bg-white p-6 shadow-lg" ]
            [ h2 [ class "pb-3 text-base text-dusty-blue-darkest" ] [ text "Keyboard Commands" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Actions" ]
            , keyboardCommandItem "Shortcuts" [ "?" ]
            , keyboardCommandItem "Search" [ "/" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Navigation" ]
            , keyboardCommandItem "Next / Previous Post" [ "J", "K" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Channels" ]
            , keyboardCommandItem "Compose a Post" [ "C" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Posts" ]
            , keyboardCommandItem "Dismiss from Inbox" [ "E" ]
            , keyboardCommandItem "Move to Inbox" [ "⌘", "E" ]
            , keyboardCommandItem "Reply" [ "R" ]
            , keyboardCommandItem "Send" [ "⌘", "enter" ]
            , keyboardCommandItem "Send + Resolve" [ "⌘", "shift", "enter" ]
            , keyboardCommandItem "Close Reply Editor" [ "esc" ]
            , h3 [ class "pt-6 pb-2 text-sm font-bold text-dusty-blue-darkest" ] [ text "Pages" ]
            , keyboardCommandJumpItem "Jump to Inbox" "i"
            , keyboardCommandJumpItem "Jump to Feed" "F"
            ]
        ]


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


fullSidebar : Config -> Html msg
fullSidebar config =
    div
        [ classList
            [ ( "fixed w-48 h-full min-h-screen z-40", True )
            ]
        ]
        [ div [ class "p-4 pt-4" ]
            [ a [ Route.href Route.Spaces, class "block ml-2 no-underline" ]
                [ div [ class "mb-2" ] [ Space.avatar Avatar.Small config.space ]
                , div [ class "mb-2 font-headline font-bold text-lg text-dusty-blue-darkest truncate" ] [ text (Space.name config.space) ]
                ]
            ]
        , div [ class "absolute pl-3 w-full overflow-y-auto", style "top" "110px", style "bottom" "70px" ]
            [ ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                [ navLink config.space "Inbox" (Just <| Route.Inbox (Route.Inbox.init (Space.slug config.space))) config.currentRoute
                , navLink config.space "Feed" (Just <| Route.Posts (Route.Posts.init (Space.slug config.space))) config.currentRoute
                ]
            , bookmarkList config
            , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                [ navLink config.space "People" (Just <| Route.SpaceUsers (Route.SpaceUsers.init (Space.slug config.space))) config.currentRoute
                , navLink config.space "Channels" (Just <| Route.Groups (Route.Groups.init (Space.slug config.space))) config.currentRoute
                , navLink config.space "Settings" (Just <| Route.Settings (Route.Settings.init (Space.slug config.space) Route.Settings.Preferences)) config.currentRoute
                , navLink config.space "Help" (Just <| Route.Help (Route.Help.init (Space.slug config.space))) config.currentRoute
                ]
            ]
        , div [ class "absolute w-full", style "bottom" "0.75rem", style "left" "0.75rem" ]
            [ a [ Route.href Route.UserSettings, class "flex items-center p-2 no-underline border-turquoise hover:bg-grey rounded transition-bg" ]
                [ div [ class "flex-no-shrink" ] [ SpaceUser.avatar Avatar.Small config.spaceUser ]
                , div [ class "flex-grow ml-2 text-sm text-dusty-blue-darker leading-normal overflow-hidden" ]
                    [ div [] [ text "Signed in as" ]
                    , div [ class "font-bold truncate" ] [ text (SpaceUser.displayName config.spaceUser) ]
                    ]
                ]
            ]
        ]


bookmarkList : Config -> Html msg
bookmarkList config =
    let
        slug =
            Space.slug config.space

        linkify group =
            navLink config.space ("#" ++ Group.name group) (Just <| Route.Group (Route.Group.init slug (Group.id group))) config.currentRoute

        links =
            config.bookmarks
                |> List.sortBy Group.name
                |> List.map linkify
    in
    ul [ class "mb-4 list-reset leading-semi-loose select-none" ] links


navLink : Space -> String -> Maybe Route -> Maybe Route -> Html msg
navLink space title maybeRoute maybeCurrentRoute =
    let
        currentItem route =
            li [ class "flex items-center" ]
                [ a
                    [ Route.href route
                    , class "block w-full pl-3 pr-2 mr-2 no-underline truncate text-dusty-blue-darkest font-bold bg-grey transition-bg rounded-full"
                    ]
                    [ text title
                    ]
                ]

        nonCurrentItem route =
            li [ class "flex items-center" ]
                [ a
                    [ Route.href route
                    , class "block w-full pl-3 pr-2 mr-2 no-underline truncate text-dusty-blue-dark bg-white transition-bg hover:bg-grey-light rounded-full"
                    ]
                    [ text title ]
                ]
    in
    case ( maybeRoute, maybeCurrentRoute ) of
        ( Just (Route.Inbox params), Just (Route.Inbox _) ) ->
            currentItem (Route.Inbox params)

        ( Just (Route.Posts params), Just (Route.Posts _) ) ->
            currentItem (Route.Posts params)

        ( Just (Route.Settings params), Just (Route.Settings _) ) ->
            currentItem (Route.Settings params)

        ( Just (Route.Group params), Just (Route.Group currentParams) ) ->
            if Route.Group.hasSamePath params currentParams then
                currentItem (Route.Group params)

            else
                nonCurrentItem (Route.Group params)

        ( Just (Route.Groups params), Just (Route.Groups _) ) ->
            currentItem (Route.Groups params)

        ( Just route, Just currentRoute ) ->
            if route == currentRoute then
                currentItem route

            else
                nonCurrentItem route

        ( _, _ ) ->
            li [ class "flex" ]
                [ a
                    [ href "#"
                    , class "ml-2 no-underline truncate text-dusty-blue-dark"
                    ]
                    [ text title ]
                ]
