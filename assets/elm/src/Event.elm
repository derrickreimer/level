module Event exposing (Event(..), decodeEvent)

import Connection exposing (Connection)
import Data.Group exposing (Group)
import Data.Post exposing (Post)
import Data.Reply exposing (Reply)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Json.Decode as Decode
import Subscription.GroupSubscription as GroupSubscription
import Subscription.PostSubscription as PostSubscription
import Subscription.SpaceSubscription as SpaceSubscription
import Subscription.SpaceUserSubscription as SpaceUserSubscription



-- TYPES


type Event
    = GroupBookmarked Group
    | GroupUnbookmarked Group
    | PostCreated ( Post, Connection Reply )
    | PostUpdated Post
    | PostSubscribed Post
    | PostUnsubscribed Post
    | MentionsDismissed Post
    | UserMentioned Post
    | GroupMembershipUpdated Group
    | GroupUpdated Group
    | ReplyCreated Reply
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
        [ -- SPACE USER EVENTS
          Decode.map GroupBookmarked SpaceUserSubscription.groupBookmarkedDecoder
        , Decode.map GroupUnbookmarked SpaceUserSubscription.groupUnbookmarkedDecoder
        , Decode.map PostSubscribed SpaceUserSubscription.postSubscribedDecoder
        , Decode.map PostUnsubscribed SpaceUserSubscription.postUnsubscribedDecoder
        , Decode.map UserMentioned SpaceUserSubscription.userMentionedDecoder
        , Decode.map MentionsDismissed SpaceUserSubscription.mentionsDismissedDecoder

        -- GROUP EVENTS
        , Decode.map GroupUpdated GroupSubscription.groupUpdatedDecoder
        , Decode.map PostCreated GroupSubscription.postCreatedDecoder
        , Decode.map GroupMembershipUpdated GroupSubscription.groupMembershipUpdatedDecoder

        -- POST EVENTS
        , Decode.map PostUpdated PostSubscription.postUpdatedDecoder
        , Decode.map ReplyCreated PostSubscription.replyCreatedDecoder

        -- SPACE EVENTS
        , Decode.map SpaceUpdated SpaceSubscription.spaceUpdatedDecoder
        , Decode.map SpaceUserUpdated SpaceSubscription.spaceUserUpdatedDecoder
        ]
