module Layout.UserMobile exposing (Config, Control(..), layout, rightSidebar)

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
    { globals : Globals
    , viewer : User
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
                    [ class "absolute w-56 pin-t pin-l pin-b shadow-lg bg-grey-lighter"
                    , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed config.onNoOp))
                    ]
                    [ div [ class "absolute pin-b w-full" ]
                        [ a [ Route.href Route.UserSettings, class "flex items-center p-4 no-underline border-turquoise hover:bg-grey transition-bg" ]
                            [ div [ class "flex-no-shrink" ] [ User.avatar Avatar.Small config.viewer ]
                            , div [ class "flex-grow ml-3 text-sm text-dusty-blue-darker leading-normal overflow-hidden" ]
                                [ div [] [ text "Signed in as" ]
                                , div [ class "font-bold truncate" ] [ text (User.displayName config.viewer) ]
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
                [ Icons.logomark ]

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
