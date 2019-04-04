module Layout.SpaceSidebar exposing (Config, view)

import Avatar
import Filter
import Globals exposing (Globals)
import Group exposing (Group)
import GroupFilters
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import InboxStateFilter
import Post exposing (Post)
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
import Set exposing (Set)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import User exposing (User)
import View.Helpers exposing (viewIf, viewUnless)



-- TYPES


type alias Config =
    { globals : Globals
    , space : Space
    , spaceUser : SpaceUser
    }



-- VIEW


view : Config -> Html msg
view config =
    let
        spaceSlug =
            Space.slug config.space

        sentByMeParams =
            spaceSlug
                |> Route.Posts.init
                |> Route.Posts.setAuthor (Just <| SpaceUser.handle config.spaceUser)
                |> Route.Posts.setInboxState InboxStateFilter.All

        hasUnreads recipientIds =
            config.globals.repo
                |> Repo.getAllPosts
                |> List.filter (Post.withRecipients (Just recipientIds))
                |> List.filter (Post.withInboxState InboxStateFilter.Unread)
                |> List.isEmpty
                |> not

        ( recipientsWithUnreads, recipientsWithoutUnreads ) =
            config.globals.repo
                |> Repo.getAllPosts
                |> List.filter (Post.withSpace (Space.id config.space))
                |> List.filter Post.isDirect
                |> List.map Post.recipientIds
                |> List.map (\ids -> List.sort ids)
                |> Set.fromList
                |> Set.toList
                |> List.partition hasUnreads
    in
    div []
        [ div [ class "p-4 pt-1" ]
            [ a [ Route.href (Route.Posts (Route.Posts.init spaceSlug)), class "block p-2 rounded no-underline" ]
                [ div [ class "mb-2" ] [ Space.avatar Avatar.Small config.space ]
                , div [ class "font-headline font-bold text-lg text-dusty-blue-darkest truncate" ] [ text (Space.name config.space) ]
                ]
            ]
        , div [ class "absolute px-3 w-full overflow-y-auto", style "top" "102px", style "bottom" "70px" ]
            [ ul [ class "mb-6 list-reset leading-semi-loose select-none" ]
                [ sidebarLink "Home" Nothing (Route.Posts (Route.Posts.init spaceSlug)) config.globals.currentRoute
                , sidebarLink "Sent" Nothing (Route.Posts sentByMeParams) config.globals.currentRoute
                ]
            , unreadList config recipientsWithUnreads
            , bookmarkList config
            , peopleList config recipientsWithoutUnreads
            , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                [ sidebarLink "Settings" Nothing (Route.Settings (Route.Settings.init spaceSlug Route.Settings.Preferences)) config.globals.currentRoute
                , sidebarLink "Integrations" Nothing (Route.Apps (Route.Apps.init spaceSlug)) config.globals.currentRoute
                , sidebarLink "Help" Nothing (Route.Help (Route.Help.init spaceSlug)) config.globals.currentRoute
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



-- INTERNAL


unreadList : Config -> List (List Id) -> Html msg
unreadList config recipientsWithUnreads =
    let
        spaceSlug =
            Space.slug config.space

        repo =
            config.globals.repo

        channels =
            repo
                |> Repo.getGroupsBySpaceId (Space.id config.space)
                |> List.filter (GroupFilters.hasUnreads repo)
                |> List.sortBy Group.name
                |> List.map (channelLink config True)

        directRecipients =
            recipientsWithUnreads
                |> List.map (directMessageLink config True)

        allUnreads =
            channels ++ directRecipients
    in
    viewUnless (List.isEmpty allUnreads) <|
        div []
            [ h3 [ class "mb-1p5 pl-3 font-sans text-md text-dusty-blue-dark" ] [ text "Unread" ]
            , ul [ class "mb-6 list-reset leading-semi-loose select-none" ] allUnreads
            ]


peopleList : Config -> List (List Id) -> Html msg
peopleList config recipientsWithoutUnreads =
    let
        spaceSlug =
            Space.slug config.space

        listItems =
            recipientsWithoutUnreads
                |> List.map (directMessageLink config False)
    in
    div []
        [ h3 [ class "mb-1p5 pl-3 font-sans text-md" ]
            [ a
                [ Route.href (Route.SpaceUsers (Route.SpaceUsers.init spaceSlug))
                , class "text-dusty-blue-dark no-underline"
                ]
                [ text "People" ]
            ]
        , viewUnless (List.isEmpty listItems) <|
            ul [ class "mb-6 list-reset leading-semi-loose select-none" ] listItems

        -- This is kind of a hack, we should clean it up.
        , viewIf (List.isEmpty listItems) <|
            ul [ class "mb-6 list-reset leading-semi-loose select-none" ]
                [ directMessageLink config False [ SpaceUser.id config.spaceUser ] ]
        ]


bookmarkList : Config -> Html msg
bookmarkList config =
    let
        spaceSlug =
            Space.slug config.space

        repo =
            config.globals.repo

        channels =
            repo
                |> Repo.getGroupsBySpaceId (Space.id config.space)
                |> List.filter (Filter.all [ not << GroupFilters.hasUnreads repo, Group.isBookmarked ])
                |> List.sortBy Group.name
    in
    div []
        [ h3 [ class "mb-1p5 pl-3 font-sans text-md" ]
            [ a
                [ Route.href (Route.Groups (Route.Groups.init spaceSlug))
                , class "text-dusty-blue-dark no-underline"
                ]
                [ text "Channels" ]
            ]
        , viewUnless (List.isEmpty channels) <|
            ul [ class "mb-6 list-reset leading-semi-loose select-none" ] (List.map (channelLink config False) channels)
        ]


channelLink : Config -> Bool -> Group -> Html msg
channelLink config hasUnreads group =
    let
        slug =
            Space.slug config.space

        params =
            if hasUnreads then
                Route.Group.init slug (Group.name group)
                    |> Route.Group.setInboxState InboxStateFilter.Undismissed

            else
                Route.Group.init slug (Group.name group)

        route =
            Route.Group params

        currentRoute =
            config.globals.currentRoute

        isCurrent =
            Route.isCurrent route currentRoute

        privacyIcon =
            if Group.isPrivate group then
                div [ class "flex-no-grow mr-2" ] [ Icons.lock ]

            else
                text ""
    in
    li []
        [ a
            [ Route.href route
            , classList
                [ ( "flex items-center w-full pl-3 pr-2 mr-2 no-underline transition-bg rounded-full", True )
                , ( "text-dusty-blue-darker bg-white hover:bg-grey-light", not isCurrent )
                , ( "text-dusty-blue-darkest bg-grey font-bold", isCurrent )
                , ( "bg-gold", isCurrent && hasUnreads )
                ]
            ]
            [ viewIf hasUnreads <|
                div [ class "absolute -ml-4 mr-2 flex-no-shrink w-2 h-2 bg-orange rounded-full shadow-white" ] []
            , div [ class "flex-no-grow mr-1" ] [ Icons.octothorpe ]
            , div [ class "mr-2 flex-shrink truncate" ] [ text <| Group.name group ]
            , privacyIcon
            ]
        ]


directMessageLink : Config -> Bool -> List Id -> Html msg
directMessageLink config hasUnreads recipientIds =
    let
        recipients =
            config.globals.repo
                |> Repo.getSpaceUsers recipientIds

        recipientsLabel =
            case recipients of
                [ singleRecipient ] ->
                    SpaceUser.displayName singleRecipient

                _ ->
                    recipients
                        |> List.filter (\su -> SpaceUser.id su /= SpaceUser.id config.spaceUser)
                        |> List.map SpaceUser.displayName
                        |> String.join ", "

        params =
            if hasUnreads then
                Route.Posts.init (Space.slug config.space)
                    |> Route.Posts.clearFilters
                    |> Route.Posts.setRecipients (Just <| List.map SpaceUser.handle recipients)
                    |> Route.Posts.setInboxState InboxStateFilter.Undismissed

            else
                Route.Posts.init (Space.slug config.space)
                    |> Route.Posts.clearFilters
                    |> Route.Posts.setRecipients (Just <| List.map SpaceUser.handle recipients)

        route =
            Route.Posts params

        currentRoute =
            config.globals.currentRoute

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
                , ( "bg-gold", isCurrent && hasUnreads )
                ]
            ]
            [ viewIf hasUnreads <|
                div [ class "absolute -ml-4 mr-2 flex-no-shrink w-2 h-2 bg-orange rounded-full shadow-white" ] []
            , div [ class "flex-no-grow mr-1" ] [ Icons.person ]
            , div [ class "mr-2 flex-shrink truncate" ] [ text recipientsLabel ]
            ]
        ]


sidebarLink : String -> Maybe (Html msg) -> Route -> Maybe Route -> Html msg
sidebarLink title maybeIcon route currentRoute =
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
