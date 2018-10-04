module View.SpaceLayout exposing (layout)

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


layout : SpaceUser -> Space -> List Group -> Maybe Route -> List (Html msg) -> Html msg
layout viewer space bookmarks maybeCurrentRoute nodes =
    div [ class "font-sans font-antialised" ]
        [ fullSidebar viewer space bookmarks maybeCurrentRoute
        , narrowSidebar viewer space bookmarks maybeCurrentRoute
        , div [ class "ml-24 lg:ml-56" ] nodes
        ]


fullSidebar : SpaceUser -> Space -> List Group -> Maybe Route -> Html msg
fullSidebar viewer space bookmarks maybeCurrentRoute =
    div [ class "fixed bg-grey-lighter border-r w-48 h-full min-h-screen hidden lg:block" ]
        [ div [ class "p-4" ]
            [ a [ Route.href Route.Spaces, class "block ml-2 no-underline" ]
                [ div [ class "mb-2" ] [ Space.avatar Avatar.Small space ]
                , div [ class "mb-6 font-extrabold text-lg text-dusty-blue-darkest" ] [ text (Space.name space) ]
                ]
            , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                [ navLink space "Inbox" (Just <| Route.Inbox (Route.Inbox.init (Space.slug space))) maybeCurrentRoute
                , navLink space "Activity" (Just <| Route.Posts (Route.Posts.init (Space.slug space))) maybeCurrentRoute
                , navLink space "Drafts" Nothing maybeCurrentRoute
                ]
            , groupLinks space bookmarks maybeCurrentRoute
            , navLink space "Groups" (Just <| Route.Groups (Route.Groups.init (Space.slug space))) maybeCurrentRoute
            ]
        , div [ class "absolute pin-b w-full" ]
            [ a [ Route.href Route.UserSettings, class "flex p-4 no-underline border-turquoise hover:bg-grey transition-bg" ]
                [ div [] [ SpaceUser.avatar Avatar.Small viewer ]
                , div [ class "ml-2 -mt-1 text-sm text-dusty-blue-darker leading-normal" ]
                    [ div [] [ text "Signed in as" ]
                    , div [ class "font-bold" ] [ text (SpaceUser.displayName viewer) ]
                    ]
                ]
            ]
        ]


narrowSidebar : SpaceUser -> Space -> List Group -> Maybe Route -> Html msg
narrowSidebar viewer space bookmarks maybeCurrentRoute =
    div [ class "fixed w-24 h-full min-h-screen lg:hidden" ]
        [ div [ class "p-4" ]
            [ a [ Route.href Route.Spaces, class "block ml-2 no-underline" ]
                [ div [ class "mb-2" ] [ Space.avatar Avatar.Small space ]
                ]
            ]
        ]


groupLinks : Space -> List Group -> Maybe Route -> Html msg
groupLinks space groups maybeCurrentRoute =
    let
        slug =
            Space.slug space

        linkify group =
            navLink space (Group.name group) (Just <| Route.Group (Route.Group.init slug (Group.id group))) maybeCurrentRoute

        links =
            groups
                |> List.sortBy Group.name
                |> List.map linkify
    in
    ul [ class "mb-4 list-reset leading-semi-loose select-none" ] links


navLink : Space -> String -> Maybe Route -> Maybe Route -> Html msg
navLink space title maybeRoute maybeCurrentRoute =
    let
        link route =
            a
                [ route
                , class "ml-2 text-dusty-blue-darkest no-underline truncate"
                ]
                [ text title ]

        currentItem route =
            li [ class "flex items-center font-bold" ]
                [ div [ class "flex-no-shrink -ml-1 w-1 h-5 bg-turquoise rounded-full" ] []
                , link (Route.href route)
                ]

        nonCurrentItem route =
            li [ class "flex" ] [ link (Route.href route) ]
    in
    case ( maybeRoute, maybeCurrentRoute ) of
        ( Just (Route.Inbox params), Just (Route.Inbox _) ) ->
            currentItem (Route.Inbox params)

        ( Just (Route.Posts params), Just (Route.Posts _) ) ->
            currentItem (Route.Posts params)

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
            li [ class "flex" ] [ link (href "#") ]
