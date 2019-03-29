module Layout.SpaceMobile exposing (Config, Control(..), layout, rightSidebar)

-- TODO:
-- - Figure out how to render flash notices

import Avatar exposing (personAvatar, thingAvatar)
import Flash exposing (Flash)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import InboxStateFilter
import Json.Decode as Decode
import Layout.SpaceSidebar as SpaceSidebar
import Lazy exposing (Lazy(..))
import Post exposing (Post)
import Repo
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
    { globals : Globals
    , space : Space
    , spaceUser : SpaceUser
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

        bookmarks =
            config.globals.repo
                |> Repo.getBookmarks (Space.id config.space)
                |> List.sortBy Group.name

        sentByMeParams =
            spaceSlug
                |> Route.Posts.init
                |> Route.Posts.setAuthor (Just <| SpaceUser.handle config.spaceUser)
                |> Route.Posts.setInboxState InboxStateFilter.All
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
                    [ SpaceSidebar.view
                        { globals = config.globals
                        , space = config.space
                        , spaceUser = config.spaceUser
                        }
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


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )
