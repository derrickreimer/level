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



-- TYPES


type alias Config msg =
    { onToggleNotifications : msg
    , onInternalLinkClicked : String -> msg
    }



-- VIEW


panelView : Config msg -> List ResolvedNotification -> Html msg
panelView config resolvedNotifications =
    div [ class "fixed overflow-y-auto w-72 xl:w-80 pin-t pin-r pin-b bg-white shadow-lg z-50" ]
        [ div [ class "flex items-center p-3 pl-6 border-b" ]
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
            div [ class "px-6 py-4 border-b" ]
                [ div [ class "pb-3 text-md" ]
                    [ authorDisplayName resolvedPost.author
                    , space
                    , span [] [ text "posted a message" ]
                    ]
                , postPreview config resolvedPost.post
                ]

        PostClosed resolvedPost ->
            div [ class "px-6 py-4 border-b" ]
                [ div [ class "pb-3 text-md" ]
                    [ authorDisplayName resolvedPost.author
                    , space
                    , span [] [ text "resolved a post" ]
                    ]
                , postPreview config resolvedPost.post
                ]

        PostReopened resolvedPost ->
            div [ class "px-6 py-4 border-b" ]
                [ div [ class "pb-3 text-md" ]
                    [ authorDisplayName resolvedPost.author
                    , space
                    , span [] [ text "reopened a post" ]
                    ]
                , postPreview config resolvedPost.post
                ]

        ReplyCreated resolvedReply ->
            div [ class "px-6 py-4 border-b" ]
                [ div [ class "pb-3 text-md" ]
                    [ authorDisplayName resolvedReply.author
                    , space
                    , span [] [ text "replied to a post" ]
                    ]
                , replyPreview config resolvedReply.reply
                ]

        PostReactionCreated postReaction ->
            text ""

        ReplyReactionCreated replyReaction ->
            text ""



-- PRIVATE


authorDisplayName : ResolvedAuthor -> Html msg
authorDisplayName resolvedAuthor =
    span [ class "font-bold" ]
        [ text <| ResolvedAuthor.displayName resolvedAuthor ]


space : Html msg
space =
    text " "


postPreview : Config msg -> Post -> Html msg
postPreview config post =
    div [ class "px-3 py-2 bg-grey-light rounded-xl text-md" ]
        [ div [ class "markdown break-words overflow-hidden", style "max-height" "72px" ]
            [ RenderedHtml.node
                { html = Post.bodyHtml post
                , onInternalLinkClicked = config.onInternalLinkClicked
                }
            ]
        ]


replyPreview : Config msg -> Reply -> Html msg
replyPreview config reply =
    div [ class "px-3 py-2 bg-grey-light rounded-xl text-md" ]
        [ div [ class "markdown break-words overflow-hidden", style "max-height" "72px" ]
            [ RenderedHtml.node
                { html = Reply.bodyHtml reply
                , onInternalLinkClicked = config.onInternalLinkClicked
                }
            ]
        ]
