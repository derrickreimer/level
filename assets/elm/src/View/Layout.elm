module View.Layout exposing (appLayout, spaceLayout, userLayout)

import Avatar exposing (personAvatar, thingAvatar)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Lazy exposing (Lazy(..))
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Groups
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import User exposing (User)
import View.Helpers exposing (displayName)



-- VIEWS


appLayout : List (Html msg) -> Html msg
appLayout nodes =
    div
        [ class "font-sans font-antialised"
        , Html.Attributes.attribute "data-stretchy-filter" ".js-stretchy"
        ]
        nodes


spaceLayout : Repo -> SpaceUser -> Space -> List Group -> Maybe Route -> List (Html msg) -> Html msg
spaceLayout repo viewer space bookmarkedGroups maybeCurrentRoute nodes =
    appLayout
        ([ spaceSidebar repo viewer space bookmarkedGroups maybeCurrentRoute ]
            ++ nodes
        )


userLayout : Lazy User -> Html msg -> Html msg
userLayout lazyUser bodyView =
    div
        [ class "container mx-auto p-6 font-sans font-antialised"
        , Html.Attributes.attribute "data-stretchy-filter" ".js-stretchy"
        ]
        [ div [ class "flex pb-16 sm:pb-16 items-center" ]
            [ a [ href "/spaces", class "logo logo-sm" ]
                [ Icons.logo ]
            , div [ class "flex flex-grow justify-end" ]
                [ currentUserView lazyUser ]
            ]
        , bodyView
        ]



-- INTERNAL


currentUserView : Lazy User -> Html msg
currentUserView lazyUser =
    case lazyUser of
        Loaded user ->
            let
                userData =
                    User.getCachedData user
            in
            a [ href "#", class "flex items-center no-underline text-dusty-blue-darker" ]
                [ div [] [ Avatar.personAvatar Avatar.Small userData ]
                , div [ class "ml-2 text-sm leading-normal" ]
                    [ div [] [ text "Signed in as" ]
                    , div [ class "font-bold" ] [ text (displayName userData) ]
                    ]
                ]

        NotLoaded ->
            -- This is a hack to prevent any vertical shifting when the actual user is loaded
            div [ class "text-sm leading-normal invisible" ]
                [ div [] [ text "Signed in as" ]
                , div [] [ text "(loading)" ]
                ]


spaceSidebar : Repo -> SpaceUser -> Space -> List Group -> Maybe Route -> Html msg
spaceSidebar repo viewer space bookmarkedGroups maybeCurrentRoute =
    let
        viewerData =
            Repo.getSpaceUser repo viewer

        spaceData =
            Repo.getSpace repo space

        slug =
            Space.getSlug space
    in
    div [ class "fixed bg-grey-lighter border-r w-48 h-full min-h-screen" ]
        [ div [ class "p-4" ]
            [ a [ href "/spaces", class "block ml-2 no-underline" ]
                [ div [ class "mb-2" ] [ thingAvatar Avatar.Small spaceData ]
                , div [ class "mb-6 font-extrabold text-lg text-dusty-blue-darkest tracking-semi-tight" ] [ text spaceData.name ]
                ]
            , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                [ spaceSidebarLink space "Inbox" (Just <| Route.Inbox slug) maybeCurrentRoute
                , spaceSidebarLink space "Everything" Nothing maybeCurrentRoute
                , spaceSidebarLink space "Drafts" Nothing maybeCurrentRoute
                ]
            , groupLinks repo space bookmarkedGroups maybeCurrentRoute
            , spaceSidebarLink space "Groups" (Just <| Route.Groups (Route.Groups.Root slug)) maybeCurrentRoute
            ]
        , div [ class "absolute pin-b w-full" ]
            [ a [ Route.href (Route.UserSettings slug), class "flex p-4 no-underline border-turquoise hover:bg-grey transition-bg" ]
                [ div [] [ personAvatar Avatar.Small viewerData ]
                , div [ class "ml-2 -mt-1 text-sm text-dusty-blue-darker leading-normal" ]
                    [ div [] [ text "Signed in as" ]
                    , div [ class "font-bold" ] [ text (displayName viewerData) ]
                    ]
                ]
            ]
        ]


groupLinks : Repo -> Space -> List Group -> Maybe Route -> Html msg
groupLinks repo space groups maybeCurrentRoute =
    let
        slug =
            Space.getSlug space

        linkify group =
            spaceSidebarLink space group.name (Just <| Route.Group slug group.id) maybeCurrentRoute

        links =
            groups
                |> Repo.getGroups repo
                |> List.sortBy .name
                |> List.map linkify
    in
    ul [ class "mb-4 list-reset leading-semi-loose select-none" ] links


spaceSidebarLink : Space -> String -> Maybe Route -> Maybe Route -> Html msg
spaceSidebarLink space title maybeRoute maybeCurrentRoute =
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
    in
    case ( maybeRoute, maybeCurrentRoute ) of
        ( Just (Route.Groups params), Just (Route.Groups _) ) ->
            currentItem (Route.Groups params)

        ( Just route, Just currentRoute ) ->
            if route == currentRoute then
                currentItem route

            else
                li [ class "flex" ] [ link (Route.href route) ]

        ( _, _ ) ->
            li [ class "flex" ] [ link (href "#") ]
