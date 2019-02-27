module Event exposing (Event(..), decodeEvent)

import Connection exposing (Connection)
import Group exposing (Group)
import Json.Decode as Decode
import Post exposing (Post)
import Reply exposing (Reply)
import ResolvedPostWithReplies exposing (ResolvedPostWithReplies)
import ResolvedSpace exposing (ResolvedSpace)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Subscription.GroupSubscription as GroupSubscription
import Subscription.SpaceSubscription as SpaceSubscription
import Subscription.SpaceUserSubscription as SpaceUserSubscription
import Subscription.UserSubscription as UserSubscription



-- TYPES


type Event
    = SpaceJoined ( ResolvedSpace, SpaceUser )
    | GroupCreated Group
    | GroupBookmarked Group
    | GroupUnbookmarked Group
    | PostCreated ResolvedPostWithReplies
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
    | PostsMarkedAsUnread (List ResolvedPostWithReplies)
    | PostsMarkedAsRead (List ResolvedPostWithReplies)
    | PostsDismissed (List ResolvedPostWithReplies)
    | RepliesViewed (List Reply)
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
        , Decode.map GroupCreated SpaceUserSubscription.groupCreatedDecoder
        , Decode.map GroupUpdated SpaceUserSubscription.groupUpdatedDecoder
        , Decode.map PostCreated SpaceUserSubscription.postCreatedDecoder
        , Decode.map PostUpdated SpaceUserSubscription.postUpdatedDecoder
        , Decode.map ReplyCreated SpaceUserSubscription.replyCreatedDecoder
        , Decode.map ReplyUpdated SpaceUserSubscription.replyUpdatedDecoder
        , Decode.map ReplyDeleted SpaceUserSubscription.replyDeletedDecoder
        , Decode.map PostClosed SpaceUserSubscription.postClosedDecoder
        , Decode.map PostReopened SpaceUserSubscription.postReopenedDecoder
        , Decode.map PostDeleted SpaceUserSubscription.postDeletedDecoder
        , Decode.map PostReactionCreated SpaceUserSubscription.postReactionCreatedDecoder
        , Decode.map PostReactionDeleted SpaceUserSubscription.postReactionDeletedDecoder
        , Decode.map ReplyReactionCreated SpaceUserSubscription.replyReactionCreatedDecoder
        , Decode.map ReplyReactionDeleted SpaceUserSubscription.replyReactionDeletedDecoder
        , Decode.map GroupBookmarked SpaceUserSubscription.groupBookmarkedDecoder
        , Decode.map GroupUnbookmarked SpaceUserSubscription.groupUnbookmarkedDecoder
        , Decode.map PostsSubscribed SpaceUserSubscription.postsSubscribedDecoder
        , Decode.map PostsUnsubscribed SpaceUserSubscription.postsUnsubscribedDecoder
        , Decode.map PostsMarkedAsUnread SpaceUserSubscription.postsMarkedAsUnreadDecoder
        , Decode.map PostsMarkedAsRead SpaceUserSubscription.postsMarkedAsReadDecoder
        , Decode.map PostsDismissed SpaceUserSubscription.postsDismissedDecoder
        , Decode.map RepliesViewed SpaceUserSubscription.repliesViewedDecoder

        -- GROUP EVENTS
        , Decode.map SubscribedToGroup GroupSubscription.subscribedToGroupDecoder
        , Decode.map UnsubscribedFromGroup GroupSubscription.unsubscribedFromGroupDecoder

        -- SPACE EVENTS
        , Decode.map SpaceUpdated SpaceSubscription.spaceUpdatedDecoder
        , Decode.map SpaceUserUpdated SpaceSubscription.spaceUserUpdatedDecoder
        ]
