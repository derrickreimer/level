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
    }



-- VIEW


panelView : Config msg -> List ResolvedNotification -> Html msg
panelView config resolvedNotifications =
    div [ class "fixed overflow-y-auto w-80 xl:w-88 pin-t pin-r pin-b bg-white shadow-lg z-50" ]
        [ div [ class "flex items-center p-3 pl-4 border-b" ]
            [ h2 [ class "text-lg flex-grow" ] [ text "Notifications" ]
            , button
                [ class "flex items-center justify-center w-9 h-9 rounded-full bg-transparent hover:bg-grey transition-bg"
                , onClick config.onToggleNotifications
                ]
                [ Icons.ex ]
            ]
        , div [] (List.map (notificationView config) resolvedNotifications)
        ]


notificationView : Config msg -> ResolvedNotification -> Html msg
notificationView config resolvedNotification =
    case resolvedNotification.event of
        PostCreated resolvedPost ->
            button [ class "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full" ]
                [ div [ class "mr-3 w-6" ] [ Icons.postCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "pt-1 pb-4" ]
                        [ authorDisplayName resolvedPost.author
                        , space
                        , span [] [ text "posted a message" ]
                        ]
                    , postPreview config resolvedPost
                    ]
                ]

        PostClosed resolvedPost ->
            button [ class "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full" ]
                [ div [ class "mr-3 w-6" ] [ Icons.postClosed ]
                , div [ class "flex-grow" ]
                    [ div [ class "pt-1 pb-4" ]
                        [ authorDisplayName resolvedPost.author
                        , space
                        , span [] [ text "resolved a post" ]
                        ]
                    , postPreview config resolvedPost
                    ]
                ]

        PostReopened resolvedPost ->
            button [ class "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full" ]
                [ div [ class "mr-3 w-6" ] [ Icons.postClosed ]
                , div [ class "flex-grow" ]
                    [ div [ class "pt-1 pb-4" ]
                        [ authorDisplayName resolvedPost.author
                        , space
                        , span [] [ text "reopened a post" ]
                        ]
                    , postPreview config resolvedPost
                    ]
                ]

        ReplyCreated resolvedReply ->
            button [ class "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full" ]
                [ div [ class "mr-3 w-6" ] [ Icons.replyCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "pt-1 pb-4" ]
                        [ authorDisplayName resolvedReply.author
                        , space
                        , span [] [ text "replied to a post" ]
                        ]
                    , replyPreview config resolvedReply
                    ]
                ]

        PostReactionCreated resolvedReaction ->
            button [ class "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full" ]
                [ div [ class "mr-3 w-6" ] [ Icons.reactionCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "pt-1 pb-4" ]
                        [ spaceUserDisplayName resolvedReaction.spaceUser
                        , space
                        , span [] [ text "acknowledged a post" ]
                        ]
                    , postPreview config resolvedReaction.resolvedPost
                    ]
                ]

        ReplyReactionCreated resolvedReaction ->
            button [ class "flex text-dusty-blue-darker px-4 py-4 border-b text-left w-full" ]
                [ div [ class "mr-3 w-6" ] [ Icons.reactionCreated ]
                , div [ class "flex-grow" ]
                    [ div [ class "pt-1 pb-4" ]
                        [ spaceUserDisplayName resolvedReaction.spaceUser
                        , space
                        , span [] [ text "acknowledged a reply" ]
                        ]
                    , replyPreview config resolvedReaction.resolvedReply
                    ]
                ]



-- PRIVATE


authorDisplayName : ResolvedAuthor -> Html msg
authorDisplayName resolvedAuthor =
    span [ class "font-bold" ]
        [ text <| ResolvedAuthor.displayName resolvedAuthor ]


spaceUserDisplayName : SpaceUser -> Html msg
spaceUserDisplayName spaceUser =
    span [ class "font-bold" ]
        [ text <| SpaceUser.displayName spaceUser ]


space : Html msg
space =
    text " "


postPreview : Config msg -> ResolvedPost -> Html msg
postPreview config resolvedPost =
    div
        [ classList [ ( "flex text-md relative", True ) ]
        ]
        [ div [ class "flex-no-shrink mr-3 z-10 pt-1" ]
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
        [ div [ class "flex-no-shrink mr-3 z-10 pt-1" ]
            [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Small resolvedReply.author) ]
        , div
            [ classList
                [ ( "min-w-0 leading-normal -ml-6 px-6", True )
                , ( "py-2 bg-grey-light rounded-xl", True )
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
