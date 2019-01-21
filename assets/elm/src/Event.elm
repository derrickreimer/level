module Event exposing (Event(..), decodeEvent)

import Connection exposing (Connection)
import Group exposing (Group)
import Json.Decode as Decode
import Post exposing (Post)
import Reply exposing (Reply)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Subscription.GroupSubscription as GroupSubscription
import Subscription.PostSubscription as PostSubscription
import Subscription.SpaceSubscription as SpaceSubscription
import Subscription.SpaceUserSubscription as SpaceUserSubscription
import Subscription.UserSubscription as UserSubscription



-- TYPES


type Event
    = SpaceJoined ( Space, SpaceUser )
    | GroupBookmarked Group
    | GroupUnbookmarked Group
    | PostCreated ( Post, Connection Reply )
    | PostUpdated Post
    | PostClosed Post
    | PostReopened Post
    | PostDeleted Post
    | PostReactionCreated Post
    | PostReactionDeleted Post
    | ReplyReactionCreated Reply
    | ReplyReactionDeleted Reply
    | PostsSubscribed (List Post)
    | PostsUnsubscribed (List Post)
    | PostsMarkedAsUnread (List Post)
    | PostsMarkedAsRead (List Post)
    | PostsDismissed (List Post)
    | RepliesViewed (List Reply)
    | MentionsDismissed Post
    | UserMentioned Post
    | SubscribedToGroup Group
    | UnsubscribedFromGroup Group
    | GroupUpdated Group
    | ReplyCreated Reply
    | ReplyUpdated Reply
    | ReplyDeleted Reply
    | SpaceUpdated Space
    | SpaceUserUpdated SpaceUser
    | Unknown Decode.Value



-- DECODER


decodeEvent : Decode.Value -> Event
decodeEvent value =
    Decode.decodeValue eventDecoder value
        |> Result.withDefault (Unknown value)


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.oneOf
        [ -- USER EVENTS
          Decode.map SpaceJoined UserSubscription.spaceJoinedDecoder

        -- SPACE USER EVENTS
        , Decode.map GroupBookmarked SpaceUserSubscription.groupBookmarkedDecoder
        , Decode.map GroupUnbookmarked SpaceUserSubscription.groupUnbookmarkedDecoder
        , Decode.map PostsSubscribed SpaceUserSubscription.postsSubscribedDecoder
        , Decode.map PostsUnsubscribed SpaceUserSubscription.postsUnsubscribedDecoder
        , Decode.map PostsMarkedAsUnread SpaceUserSubscription.postsMarkedAsUnreadDecoder
        , Decode.map PostsMarkedAsRead SpaceUserSubscription.postsMarkedAsReadDecoder
        , Decode.map PostsDismissed SpaceUserSubscription.postsDismissedDecoder
        , Decode.map UserMentioned SpaceUserSubscription.userMentionedDecoder
        , Decode.map MentionsDismissed SpaceUserSubscription.mentionsDismissedDecoder
        , Decode.map RepliesViewed SpaceUserSubscription.repliesViewedDecoder

        -- GROUP EVENTS
        , Decode.map GroupUpdated GroupSubscription.groupUpdatedDecoder
        , Decode.map PostCreated GroupSubscription.postCreatedDecoder
        , Decode.map SubscribedToGroup GroupSubscription.subscribedToGroupDecoder
        , Decode.map UnsubscribedFromGroup GroupSubscription.unsubscribedFromGroupDecoder

        -- POST EVENTS
        , Decode.map PostUpdated PostSubscription.postUpdatedDecoder
        , Decode.map ReplyCreated PostSubscription.replyCreatedDecoder
        , Decode.map ReplyUpdated PostSubscription.replyUpdatedDecoder
        , Decode.map ReplyDeleted PostSubscription.replyDeletedDecoder
        , Decode.map PostClosed PostSubscription.postClosedDecoder
        , Decode.map PostReopened PostSubscription.postReopenedDecoder
        , Decode.map PostDeleted PostSubscription.postDeletedDecoder
        , Decode.map PostReactionCreated PostSubscription.postReactionCreatedDecoder
        , Decode.map PostReactionDeleted PostSubscription.postReactionDeletedDecoder
        , Decode.map ReplyReactionCreated PostSubscription.replyReactionCreatedDecoder
        , Decode.map ReplyReactionDeleted PostSubscription.replyReactionDeletedDecoder

        -- SPACE EVENTS
        , Decode.map SpaceUpdated SpaceSubscription.spaceUpdatedDecoder
        , Decode.map SpaceUserUpdated SpaceSubscription.spaceUserUpdatedDecoder
        ]
