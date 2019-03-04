module Layout.SpaceDesktop exposing (Config, layout, rightSidebar)

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
    , space : Space
    , spaceUser : SpaceUser
    , onNoOp : msg
    , onToggleKeyboardCommands : msg
    , onPageClicked : msg
    }



-- API


layout : Config msg -> List (Html msg) -> Html msg
layout config children =
    div [ class "font-sans font-antialised", onClick config.onPageClicked ]
        [ spacesSidebar config
        , div [ class "mx-auto pl-16 xl:px-24" ]
            [ fullSidebar config
            , div [ class "ml-48 xl:mx-48 relative" ] children
            ]
        , div [ class "fixed pin-t pin-r z-50", id "headway" ] []
        , Flash.view config.globals.flash
        , viewIf config.globals.showKeyboardCommands (keyboardCommandReference config)
        ]


rightSidebar : List (Html msg) -> Html msg
rightSidebar children =
    div
        [ classList
            [ ( "fixed pin-t pin-b pin-r py-4 w-48", True )
            , ( "hidden xl:block", True )
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
    a
        [ Route.href (Route.Root (Space.slug space))
        , classList
            [ ( "block mb-1 no-underline hover:opacity-100", True )
            , ( "opacity-50", not (config.space == space) )
            ]
        ]
        [ Space.avatar Avatar.Small space ]


fullSidebar : Config msg -> Html msg
fullSidebar config =
    let
        spaceSlug =
            Space.slug config.space

        bookmarks =
            config.globals.repo
                |> Repo.getBookmarks (Space.id config.space)
                |> List.sortBy Group.name
    in
    div
        [ classList
            [ ( "fixed w-48 h-full min-h-screen z-30", True )
            ]
        ]
        [ div [ class "p-4 pt-2" ]
            [ a [ Route.href (Route.Posts (Route.Posts.init spaceSlug)), class "block p-2 rounded no-underline" ]
                [ div [ class "mb-2" ] [ Space.avatar Avatar.Small config.space ]
                , div [ class "font-headline font-bold text-lg text-dusty-blue-darkest truncate" ] [ text (Space.name config.space) ]
                ]
            ]
        , div [ class "absolute pl-3 w-full overflow-y-auto", style "top" "105px", style "bottom" "70px" ]
            [ ul [ class "mb-6 list-reset leading-semi-loose select-none" ]
                [ sidebarTab "Home" Nothing (Route.Posts (Route.Posts.init spaceSlug)) config.globals.currentRoute
                ]
            , viewUnless (List.isEmpty bookmarks) <|
                div []
                    [ h3 [ class "mb-1p5 pl-3 font-sans text-md" ]
                        [ a [ Route.href (Route.Groups (Route.Groups.init spaceSlug)), class "text-dusty-blue no-underline" ] [ text "Channels" ] ]
                    , bookmarkList config bookmarks
                    ]
            , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                [ viewIf (List.isEmpty bookmarks) <|
                    sidebarTab "Channels" Nothing (Route.Groups (Route.Groups.init spaceSlug)) config.globals.currentRoute
                , sidebarTab "People" Nothing (Route.SpaceUsers (Route.SpaceUsers.init spaceSlug)) config.globals.currentRoute
                , sidebarTab "Settings" Nothing (Route.Settings (Route.Settings.init spaceSlug Route.Settings.Preferences)) config.globals.currentRoute
                , sidebarTab "Integrations" Nothing (Route.Apps (Route.Apps.init spaceSlug)) config.globals.currentRoute
                , sidebarTab "Help" Nothing (Route.Help (Route.Help.init spaceSlug)) config.globals.currentRoute
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


bookmarkList : Config msg -> List Group -> Html msg
bookmarkList config bookmarks =
    let
        slug =
            Space.slug config.space

        linkify group =
            let
                route =
                    Route.Group (Route.Group.init slug (Group.name group))

                icon =
                    if Group.isPrivate group then
                        Just Icons.lock

                    else
                        Nothing
            in
            sidebarTab ("#" ++ Group.name group) icon route config.globals.currentRoute

        links =
            List.map linkify bookmarks
    in
    ul [ class "mb-6 list-reset leading-semi-loose select-none" ] links


sidebarTab : String -> Maybe (Html msg) -> Route -> Maybe Route -> Html msg
sidebarTab title maybeIcon route currentRoute =
    let
        isCurrent =
            Route.isCurrent route currentRoute
    in
    li []
        [ a
            [ Route.href route
            , classList
                [ ( "flex items-center w-full pl-3 pr-2 mr-2 no-underline transition-bg rounded-full", True )
                , ( "text-dusty-blue-darker bg-white hover:bg-grey-light", not isCurrent )
                , ( "text-dusty-blue-darkest bg-grey font-bold", isCurrent )
                ]
            ]
            [ div [ class "mr-2 flex-shrink truncate" ] [ text title ]
            , div [ class "flex-no-grow" ] [ Maybe.withDefault (text "") maybeIcon ]
            ]
        ]
