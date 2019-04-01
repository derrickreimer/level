module Layout.SpaceSidebar exposing (Config, view)

import Avatar
import Globals exposing (Globals)
import Group exposing (Group)
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

        bookmarks =
            config.globals.repo
                |> Repo.getBookmarks (Space.id config.space)
                |> List.sortBy Group.name

        directMessageRecipients =
            config.globals.repo
                |> Repo.getAllPosts
                |> List.filter (Post.withSpace (Space.id config.space))
                |> List.filter Post.isDirect
                |> List.map Post.recipientIds
                |> List.map (\ids -> List.sort ids)
                |> Set.fromList

        sentByMeParams =
            spaceSlug
                |> Route.Posts.init
                |> Route.Posts.setAuthor (Just <| SpaceUser.handle config.spaceUser)
                |> Route.Posts.setInboxState InboxStateFilter.All
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
            , viewUnless (List.isEmpty bookmarks) <|
                div []
                    [ h3 [ class "mb-1p5 pl-3 font-sans text-base" ]
                        [ a
                            [ Route.href (Route.Groups (Route.Groups.init spaceSlug))
                            , class "text-dusty-blue no-underline"
                            ]
                            [ text "Channels" ]
                        ]
                    , bookmarkList config bookmarks
                    ]
            , viewUnless (Set.isEmpty directMessageRecipients) <|
                div []
                    [ h3 [ class "mb-1p5 pl-3 font-sans text-base text-dusty-blue" ] [ text "Direct Messages" ]
                    , directMessageList config directMessageRecipients
                    ]
            , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                [ sidebarLink "People" Nothing (Route.SpaceUsers (Route.SpaceUsers.init spaceSlug)) config.globals.currentRoute
                , sidebarLink "Channels" Nothing (Route.Groups (Route.Groups.init spaceSlug)) config.globals.currentRoute
                , sidebarLink "Settings" Nothing (Route.Settings (Route.Settings.init spaceSlug Route.Settings.Preferences)) config.globals.currentRoute
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


directMessageList : Config -> Set (List Id) -> Html msg
directMessageList config recipientLists =
    let
        listItems =
            recipientLists
                |> Set.toList
                |> List.map (directMessageLink config)
    in
    ul [ class "mb-6 list-reset leading-semi-loose select-none" ] listItems


directMessageLink : Config -> List Id -> Html msg
directMessageLink config recipientIds =
    let
        recipients =
            config.globals.repo
                |> Repo.getSpaceUsers recipientIds

        hasUnreads =
            config.globals.repo
                |> Repo.getAllPosts
                |> List.filter (Post.withRecipients (Just recipientIds))
                |> List.filter (Post.withInboxState InboxStateFilter.Unread)
                |> List.isEmpty
                |> not

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
                , ( "font-bold", hasUnreads )
                , ( "text-dusty-blue-darkest bg-grey font-bold", isCurrent )
                ]
            ]
            [ viewIf hasUnreads <|
                div [ class "absolute -ml-4 mr-2 flex-no-shrink w-2 h-2 bg-blue rounded-full shadow-white" ] []
            , div [ class "flex-no-grow mr-1" ] [ Icons.person ]
            , div [ class "mr-2 flex-shrink truncate" ] [ text recipientsLabel ]
            ]
        ]


bookmarkList : Config -> List Group -> Html msg
bookmarkList config bookmarks =
    ul [ class "mb-6 list-reset leading-semi-loose select-none" ] (List.map (groupLink config) bookmarks)


groupLink : Config -> Group -> Html msg
groupLink config group =
    let
        slug =
            Space.slug config.space

        hasUnreads =
            config.globals.repo
                |> Repo.getPostsByGroup (Group.id group) Nothing
                |> List.filter (Post.withInboxState InboxStateFilter.Unread)
                |> List.isEmpty
                |> not

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
                , ( "font-bold", hasUnreads )
                , ( "text-dusty-blue-darkest bg-grey font-bold", isCurrent )
                ]
            ]
            [ viewIf hasUnreads <|
                div [ class "absolute -ml-4 mr-2 flex-no-shrink w-2 h-2 bg-blue rounded-full shadow-white" ] []
            , div [ class "flex-no-grow mr-1" ] [ Icons.octothorpe ]
            , div [ class "mr-2 flex-shrink truncate" ] [ text <| Group.name group ]
            , privacyIcon
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
