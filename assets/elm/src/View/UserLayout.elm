module View.UserLayout exposing (layout)

import Avatar exposing (personAvatar, thingAvatar)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Lazy exposing (Lazy(..))
import Route exposing (Route)
import Route.Group
import Route.Groups
import Route.Inbox
import Route.Posts
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import User exposing (User)



-- VIEWS


layout : User -> Html msg -> Html msg
layout user bodyView =
    div
        [ class "container mx-auto p-6 font-sans font-antialised"
        ]
        [ div [ class "flex pb-16 sm:pb-16 items-center" ]
            [ a [ Route.href Route.Spaces, class "logo logo-sm" ]
                [ Icons.logo ]
            , div [ class "flex items-center flex-grow justify-end" ]
                [ currentUserView user
                , a
                    [ class "ml-4"
                    , href "/logout"
                    , rel "tooltip"
                    , title "Sign out"
                    ]
                    [ Icons.logOut ]
                ]
            ]
        , bodyView
        ]



-- INTERNAL


currentUserView : User -> Html msg
currentUserView user =
    a [ Route.href Route.UserSettings, class "flex items-center no-underline text-dusty-blue-darker" ]
        [ div [] [ User.avatar Avatar.Small user ]
        , div [ class "ml-2 text-sm leading-normal" ]
            [ div [] [ text "Signed in as" ]
            , div [ class "font-bold" ] [ text (User.displayName user) ]
            ]
        ]
