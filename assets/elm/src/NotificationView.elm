module NotificationView exposing
    ( Config
    , panelView
    )

{-| The logic for displaying a notification in the feed.


# Types

@docs Config


# View

@docs panelView

-}

import Avatar
import Globals exposing (Globals)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Notification
import NotificationSet exposing (NotificationSet)
import Post exposing (Post)
import PostReaction exposing (PostReaction)
import RenderedHtml
import Reply exposing (Reply)
import ReplyReaction exposing (ReplyReaction)
import ResolvedAuthor exposing (ResolvedAuthor)
import ResolvedNotification exposing (Event(..), ResolvedNotification)
import ResolvedPost exposing (ResolvedPost)
import ResolvedReply exposing (ResolvedReply)
import SpaceUser exposing (SpaceUser)
import TimeWithZone exposing (TimeWithZone)
import View.Helpers exposing (viewIf)



-- TYPES


type alias Config msg =
    { globals : Globals
    , onToggleNotifications : msg
    , onInternalLinkClicked : String -> msg
    , onMoreRequested : msg
    }



-- VIEW


panelView : Config msg -> NotificationSet -> Html msg
panelView config notifications =
    let
        itemViews =
            notifications
                |> NotificationSet.resolve config.globals.repo
                |> List.map (notificationView config)
    in
    div [ class "fixed font-sans font-antialised w-80 xl:w-88 pin-t pin-r pin-b bg-white shadow-dropdown z-50" ]
        [ div [ class "flex items-center p-3 pl-4 border-b" ]
            [ h2 [ class "text-lg flex-grow" ] [ text "Notifications" ]
            , button
                [ class "flex items-center justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
                , onClick config.onToggleNotifications
                ]
                [ Icons.ex ]
            ]
        , div [ class "absolute pin overflow-y-auto", style "top" "61px" ]
            [ div [] itemViews
            , viewIf (NotificationSet.hasMore notifications) <|
                div [ class "py-8 text-center" ]
                    [ button
                        [ class "btn btn-grey-outline btn-md"
                        , onClick config.onMoreRequested
                        ]
                        [ text "Load more..." ]
                    ]
            ]
        ]


notificationView : Config msg -> ResolvedNotification -> Html msg
notificationView config resolvedNotification =
    let
        notification =
            resolvedNotification.notification

        timestamp =
            View.Helpers.timeTag config.globals.now
                (TimeWithZone.setPosix (Notification.occurredAt notification) config.globals.now)
                [ class "block flex-no-grow text-sm text-dusty-blue-dark whitespace-no-wrap" ]
    in
    case resolvedNotification.event of
        PostCreated (Just resolvedPost) ->
            button
                [ classList
                    [ ( "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full leading-normal", True )
                    , ( "bg-blue-lightest", Notification.isUndismissed notification )
                    ]
                ]
                [ div [ class "mr-3 w-6" ] [ Icons.postCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "flex items-baseline pt-1 pb-4" ]
                        [ div [ class "flex-grow mr-1" ]
                            [ authorDisplayName resolvedPost.author
                            , span [] [ text " posted" ]
                            ]
                        , timestamp
                        ]
                    , postPreview config resolvedPost
                    ]
                ]

        PostClosed (Just resolvedPost) ->
            button
                [ classList
                    [ ( "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full leading-normal", True )
                    , ( "bg-blue-lightest", Notification.isUndismissed notification )
                    ]
                ]
                [ div [ class "mr-3 w-6" ] [ Icons.postClosed ]
                , div [ class "flex-grow" ]
                    [ div [ class "flex items-baseline pt-1 pb-4" ]
                        [ div [ class "flex-grow mr-1" ]
                            [ authorDisplayName resolvedPost.author
                            , span [] [ text " resolved a post" ]
                            ]
                        , timestamp
                        ]
                    , postPreview config resolvedPost
                    ]
                ]

        PostReopened (Just resolvedPost) ->
            button
                [ classList
                    [ ( "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full leading-normal", True )
                    , ( "bg-blue-lightest", Notification.isUndismissed notification )
                    ]
                ]
                [ div [ class "mr-3 w-6" ] [ Icons.postClosed ]
                , div [ class "flex-grow" ]
                    [ div [ class "flex items-baseline pt-1 pb-4" ]
                        [ div [ class "flex-grow mr-1" ]
                            [ authorDisplayName resolvedPost.author
                            , span [] [ text " reopened a post" ]
                            ]
                        , timestamp
                        ]
                    , postPreview config resolvedPost
                    ]
                ]

        ReplyCreated (Just resolvedReply) ->
            button
                [ classList
                    [ ( "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full leading-normal", True )
                    , ( "bg-blue-lightest", Notification.isUndismissed notification )
                    ]
                ]
                [ div [ class "mr-3 w-6" ] [ Icons.replyCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "flex items-baseline pt-1 pb-4" ]
                        [ div [ class "flex-grow mr-1" ]
                            [ authorDisplayName resolvedReply.author
                            , span [] [ text " replied" ]
                            ]
                        , timestamp
                        ]
                    , replyPreview config resolvedReply
                    ]
                ]

        PostReactionCreated (Just resolvedReaction) ->
            button
                [ classList
                    [ ( "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full leading-normal", True )
                    , ( "bg-blue-lightest", Notification.isUndismissed notification )
                    ]
                ]
                [ div [ class "mr-3 w-6" ] [ Icons.reactionCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "flex items-baseline pt-1 pb-4" ]
                        [ div [ class "flex-grow mr-1" ]
                            [ spaceUserDisplayName resolvedReaction.spaceUser
                            , span [] [ text " acknowledged" ]
                            ]
                        , timestamp
                        ]
                    , postPreview config resolvedReaction.resolvedPost
                    ]
                ]

        ReplyReactionCreated (Just resolvedReaction) ->
            button
                [ classList
                    [ ( "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full leading-normal", True )
                    , ( "bg-blue-lightest", Notification.isUndismissed notification )
                    ]
                ]
                [ div [ class "mr-3 w-6" ] [ Icons.reactionCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "flex items-baseline pt-1 pb-4" ]
                        [ div [ class "flex-grow mr-1" ]
                            [ spaceUserDisplayName resolvedReaction.spaceUser
                            , span [] [ text " acknowledged" ]
                            ]
                        , timestamp
                        ]
                    , replyPreview config resolvedReaction.resolvedReply
                    ]
                ]

        _ ->
            text ""



-- PRIVATE


authorDisplayName : ResolvedAuthor -> Html msg
authorDisplayName resolvedAuthor =
    span [ class "font-bold" ]
        [ text <| ResolvedAuthor.displayName resolvedAuthor ]


spaceUserDisplayName : SpaceUser -> Html msg
spaceUserDisplayName spaceUser =
    span [ class "font-bold" ]
        [ text <| SpaceUser.displayName spaceUser ]


postPreview : Config msg -> ResolvedPost -> Html msg
postPreview config resolvedPost =
    div
        [ classList [ ( "flex text-md relative", True ) ]
        ]
        [ div [ class "flex-no-shrink mr-2 z-10 pt-1" ]
            [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Small resolvedPost.author) ]
        , div
            [ classList
                [ ( "min-w-0 leading-normal -ml-6 px-6", True )
                ]
            ]
            [ div [ class "pb-1/2" ]
                [ authorLabel resolvedPost.author
                , View.Helpers.timeTag config.globals.now
                    (TimeWithZone.setPosix (Post.postedAt resolvedPost.post) config.globals.now)
                    [ class "mr-3 text-sm text-dusty-blue whitespace-no-wrap" ]
                ]
            , div []
                [ div [ class "markdown pb-1 break-words text-dusty-blue-dark max-h-16 overflow-hidden" ]
                    [ RenderedHtml.node
                        { html = Post.bodyHtml resolvedPost.post
                        , onInternalLinkClicked = config.onInternalLinkClicked
                        }
                    ]

                -- , staticFilesView (Reply.files reply)
                ]
            , div [ class "pb-1/2 flex items-start" ] [ postReactionIndicator resolvedPost ]
            ]
        ]


replyPreview : Config msg -> ResolvedReply -> Html msg
replyPreview config resolvedReply =
    div
        [ classList [ ( "flex text-md relative", True ) ]
        ]
        [ div [ class "flex-no-shrink mr-2 z-10 pt-1" ]
            [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Small resolvedReply.author) ]
        , div
            [ classList
                [ ( "min-w-0 leading-normal -ml-6 px-6", True )
                , ( "py-2 bg-grey-light rounded-xl", False )
                ]
            ]
            [ div [ class "pb-1/2" ]
                [ authorLabel resolvedReply.author
                , View.Helpers.timeTag config.globals.now
                    (TimeWithZone.setPosix (Reply.postedAt resolvedReply.reply) config.globals.now)
                    [ class "mr-3 text-sm text-dusty-blue whitespace-no-wrap" ]
                ]
            , div []
                [ div [ class "markdown pb-1 break-words text-dusty-blue-dark max-h-16 overflow-hidden" ]
                    [ RenderedHtml.node
                        { html = Reply.bodyHtml resolvedReply.reply
                        , onInternalLinkClicked = config.onInternalLinkClicked
                        }
                    ]

                -- , staticFilesView (Reply.files reply)
                ]
            , div [ class "pb-1/2 flex items-start" ] [ replyReactionIndicator resolvedReply ]
            ]
        ]


authorLabel : ResolvedAuthor -> Html msg
authorLabel author =
    span
        [ class "whitespace-no-wrap"
        ]
        [ span [ class "font-bold text-dusty-blue-dark mr-2" ] [ text <| ResolvedAuthor.displayName author ]
        , span [ class "ml-2 text-dusty-blue hidden" ] [ text <| "@" ++ ResolvedAuthor.handle author ]
        ]


postReactionIndicator : ResolvedPost -> Html msg
postReactionIndicator resolvedPost =
    let
        toggleState =
            if Post.hasReacted resolvedPost.post then
                Icons.On

            else
                Icons.Off
    in
    div
        [ class "flex relative items-center mr-6 no-outline react-button"
        ]
        [ Icons.thumbsMedium toggleState
        , viewIf (Post.reactionCount resolvedPost.post > 0) <|
            div
                [ class "ml-1 text-dusty-blue font-bold text-sm"
                ]
                [ text <| String.fromInt (Post.reactionCount resolvedPost.post) ]
        ]


replyReactionIndicator : ResolvedReply -> Html msg
replyReactionIndicator resolvedReply =
    let
        toggleState =
            if Reply.hasReacted resolvedReply.reply then
                Icons.On

            else
                Icons.Off
    in
    div
        [ class "flex relative items-center mr-6 no-outline react-button"
        ]
        [ Icons.thumbsMedium toggleState
        , viewIf (Reply.reactionCount resolvedReply.reply > 0) <|
            div
                [ class "ml-1 text-dusty-blue font-bold text-sm"
                ]
                [ text <| String.fromInt (Reply.reactionCount resolvedReply.reply) ]
        ]
