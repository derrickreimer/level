module Layout.SpaceMobile exposing (Config, layout, rightSidebar)

-- TODO:
-- - Figure out how to render flash notices

import Avatar exposing (personAvatar, thingAvatar)
import Flash exposing (Flash)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Json.Decode as Decode
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


type alias Config msg =
    { space : Space
    , spaceUser : SpaceUser
    , bookmarks : List Group
    , currentRoute : Maybe Route
    , flash : Flash
    , title : String
    , showNav : Bool
    , onNavToggled : msg
    , onSidebarToggled : msg
    , onScrollTopClicked : msg
    , onNoOp : msg
    , actionButton : Html msg
    }



-- API


layout : Config msg -> List (Html msg) -> Html msg
layout config children =
    div [ class "font-sans font-antialised", style "padding-top" "60px" ]
        [ div [ class "fixed pin-t w-full flex items-center p-3 border-b bg-grey-lighter z-40" ]
            [ div [ class "flex-no-shrink" ]
                [ button [ class "flex", onClick config.onNavToggled ] [ Space.avatar Avatar.Small config.space ]
                ]
            , div [ class "mx-2 flex-grow", onClick config.onScrollTopClicked ]
                [ h1 [ class "font-headline font-bold text-lg text-center" ] [ text config.title ]
                ]
            , div [ class "flex-no-shrink" ]
                [ config.actionButton
                ]
            ]
        , div [] children
        , viewIf config.showNav <|
            div [ class "fixed pin z-50", style "background-color" "rgba(0,0,0,0.5)", onClick config.onNavToggled ]
                [ div
                    [ class "absolute w-56 pin-t pin-l pin-b shadow-lg bg-grey-lighter"
                    , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed config.onNoOp))
                    ]
                    [ div [ class "px-6 py-4" ]
                        [ a [ Route.href Route.Spaces, class "block no-underline" ]
                            [ div [ class "mb-2" ] [ Space.avatar Avatar.Small config.space ]
                            , div [ class "mb-2 font-headline font-bold text-xl text-dusty-blue-darkest truncate" ] [ text (Space.name config.space) ]
                            ]
                        ]
                    , div [ class "absolute w-full overflow-y-auto", style "top" "120px", style "bottom" "60px" ]
                        [ ul [ class "mb-6 list-reset leading-semi-loose select-none" ]
                            [ navLink config.space "Inbox" (Just <| Route.Inbox (Route.Inbox.init (Space.slug config.space))) config.currentRoute
                            , navLink config.space "Activity" (Just <| Route.Posts (Route.Posts.init (Space.slug config.space))) config.currentRoute
                            ]
                        , bookmarkList config
                        , ul [ class "mb-6 list-reset leading-semi-loose select-none" ]
                            [ navLink config.space "People" (Just <| Route.SpaceUsers (Route.SpaceUsers.init (Space.slug config.space))) config.currentRoute
                            , navLink config.space "Groups" (Just <| Route.Groups (Route.Groups.init (Space.slug config.space))) config.currentRoute
                            , navLink config.space "Settings" (Just <| Route.Settings (Route.Settings.init (Space.slug config.space) Route.Settings.Preferences)) config.currentRoute
                            , navLink config.space "Help" (Just <| Route.Help (Route.Help.init (Space.slug config.space))) config.currentRoute
                            ]
                        ]
                    , div [ class "absolute pin-b w-full" ]
                        [ a [ Route.href Route.UserSettings, class "flex items-center p-4 no-underline border-turquoise hover:bg-grey transition-bg" ]
                            [ div [ class "flex-no-shrink" ] [ SpaceUser.avatar Avatar.Small config.spaceUser ]
                            , div [ class "flex-grow ml-3 text-sm text-dusty-blue-darker leading-normal overflow-hidden" ]
                                [ div [] [ text "Signed in as" ]
                                , div [ class "font-bold truncate" ] [ text (SpaceUser.displayName config.spaceUser) ]
                                ]
                            ]
                        ]
                    ]
                ]
        ]


rightSidebar : Config msg -> List (Html msg) -> Html msg
rightSidebar config children =
    div [ class "fixed pin z-50", style "background-color" "rgba(0,0,0,0.5)", onClick config.onSidebarToggled ]
        [ div
            [ class "absolute w-56 pin-t pin-r pin-b shadow-lg bg-grey-lighter"
            , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed config.onNoOp))
            ]
            children
        ]



-- PRIVATE


bookmarkList : Config msg -> Html msg
bookmarkList config =
    let
        slug =
            Space.slug config.space

        linkify group =
            navLink config.space (Group.name group) (Just <| Route.Group (Route.Group.init slug (Group.id group))) config.currentRoute

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
            li [ class "flex items-center border-r-4 border-turquoise" ]
                [ a
                    [ Route.href route
                    , class "block w-full px-6 no-underline truncate text-dusty-blue-darkest font-bold text-lg bg-grey"
                    ]
                    [ text title
                    ]
                ]

        nonCurrentItem route =
            li [ class "flex items-center" ]
                [ a
                    [ Route.href route
                    , class "block w-full px-6 no-underline truncate text-dusty-blue-dark text-lg"
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


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )
