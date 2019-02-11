module Layout.SpaceMobile exposing (Config, Control(..), layout, rightSidebar)

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


type Control msg
    = Back Route
    | ShowNav
    | ShowSidebar
    | Custom (Html msg)
    | NoControl


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
    , leftControl : Control msg
    , rightControl : Control msg
    }



-- API


layout : Config msg -> List (Html msg) -> Html msg
layout config children =
    let
        spaceSlug =
            Space.slug config.space
    in
    div [ class "font-sans font-antialised", style "padding-top" "60px" ]
        [ div [ class "fixed pin-t w-full flex items-center p-3 border-b bg-white z-40" ]
            [ div [ class "flex-no-shrink" ]
                [ controlView config config.leftControl
                ]
            , div [ class "mx-2 flex-grow", onClick config.onScrollTopClicked ]
                [ h1 [ class "font-headline font-bold text-lg text-center" ] [ text config.title ]
                ]
            , div [ class "flex-no-shrink" ]
                [ controlView config config.rightControl
                ]
            ]
        , div [ class "leading-normal" ] children
        , viewIf config.showNav <|
            div [ class "fixed pin z-50", style "background-color" "rgba(0,0,0,0.5)", onClick config.onNavToggled ]
                [ div
                    [ class "absolute w-56 pin-t pin-l pin-b shadow-lg bg-white"
                    , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed config.onNoOp))
                    ]
                    [ div [ class "p-4 pt-3" ]
                        [ a [ Route.href Route.Spaces, class "block ml-2 no-underline" ]
                            [ div [ class "mb-2" ] [ Space.avatar Avatar.Small config.space ]
                            , div [ class "mb-2 font-headline font-bold text-lg text-dusty-blue-darkest truncate" ] [ text (Space.name config.space) ]
                            ]
                        ]
                    , div [ class "absolute px-3 w-full overflow-y-auto", style "top" "105px", style "bottom" "70px" ]
                        [ ul [ class "mb-6 list-reset leading-semi-loose select-none" ]
                            [ sidebarTab "Home" Nothing (Route.Posts (Route.Posts.init spaceSlug)) config.currentRoute
                            ]
                        , viewUnless (List.isEmpty config.bookmarks) <|
                            div []
                                [ h3 [ class "mb-1p5 pl-3 font-sans text-sm" ]
                                    [ a [ Route.href (Route.Groups (Route.Groups.init spaceSlug)), class "text-dusty-blue no-underline" ] [ text "Channels" ] ]
                                , channelList config
                                ]
                        , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                            [ viewIf (List.isEmpty config.bookmarks) <|
                                sidebarTab "Channels" Nothing (Route.Groups (Route.Groups.init spaceSlug)) config.currentRoute
                            , sidebarTab "People" Nothing (Route.SpaceUsers (Route.SpaceUsers.init spaceSlug)) config.currentRoute
                            , sidebarTab "Settings" Nothing (Route.Settings (Route.Settings.init spaceSlug Route.Settings.Preferences)) config.currentRoute
                            , sidebarTab "Integrations" Nothing (Route.Apps (Route.Apps.init spaceSlug)) config.currentRoute
                            , sidebarTab "Help" Nothing (Route.Help (Route.Help.init spaceSlug)) config.currentRoute
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
            [ class "absolute w-56 pin-t pin-r pin-b shadow-lg bg-white"
            , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed config.onNoOp))
            ]
            children
        ]



-- PRIVATE


controlView : Config msg -> Control msg -> Html msg
controlView config control =
    case control of
        ShowNav ->
            button [ class "flex", onClick config.onNavToggled ]
                [ Space.avatar Avatar.Small config.space ]

        ShowSidebar ->
            button
                [ class "flex items-center justify-center w-9 h-9"
                , onClick config.onSidebarToggled
                ]
                [ Icons.menu ]

        Back route ->
            a
                [ Route.href route
                , class "flex items-center pl-1 w-9 h-9"
                ]
                [ Icons.arrowLeft Icons.On ]

        Custom button ->
            button

        NoControl ->
            div [ class "w-9" ] []


channelList : Config msg -> Html msg
channelList config =
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
            sidebarTab ("#" ++ Group.name group) icon route config.currentRoute

        links =
            config.bookmarks
                |> List.sortBy Group.name
                |> List.map linkify
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


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )
