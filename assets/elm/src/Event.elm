module Event exposing (Event(..), decodeEvent)

import Json.Decode as Decode
import Data.Group exposing (Group)
import Data.Post exposing (Post)
import Data.Reply exposing (Reply)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Subscription.SpaceSubscription exposing (spaceUpdatedDecoder, spaceUserUpdatedDecoder)
import Subscription.SpaceUserSubscription exposing (groupBookmarkedDecoder, groupUnbookmarkedDecoder, postSubscribedDecoder, postUnsubscribedDecoder)
import Subscription.GroupSubscription exposing (groupUpdatedDecoder, postCreatedDecoder, groupMembershipUpdatedDecoder)
import Subscription.PostSubscription exposing (postUpdatedDecoder, replyCreatedDecoder)


-- TYPES


type Event
    = GroupBookmarked Group
    | GroupUnbookmarked Group
    | PostCreated Post
    | PostUpdated Post
    | PostSubscribed Post
    | PostUnsubscribed Post
    | GroupMembershipUpdated Group
    | GroupUpdated Group
    | ReplyCreated Reply
    | SpaceUpdated Space
    | SpaceUserUpdated SpaceUser
    | Unknown



-- DECODER


decodeEvent : Decode.Value -> Event
decodeEvent value =
    Decode.decodeValue eventDecoder value
        |> Result.withDefault Unknown


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.oneOf
        [ Decode.map GroupBookmarked groupBookmarkedDecoder
        , Decode.map GroupUnbookmarked groupUnbookmarkedDecoder
        , Decode.map GroupUpdated groupUpdatedDecoder
        , Decode.map PostCreated postCreatedDecoder
        , Decode.map PostUpdated postUpdatedDecoder
        , Decode.map PostSubscribed postSubscribedDecoder
        , Decode.map PostUnsubscribed postUnsubscribedDecoder
        , Decode.map GroupMembershipUpdated groupMembershipUpdatedDecoder
        , Decode.map ReplyCreated replyCreatedDecoder
        , Decode.map SpaceUpdated spaceUpdatedDecoder
        , Decode.map SpaceUserUpdated spaceUserUpdatedDecoder
        ]
