module Event exposing (Event(..), decodeEvent)

import Json.Decode as Decode
import Data.Group exposing (Group)
import Data.Post exposing (Post)
import Data.Reply exposing (Reply)
import Subscription.SpaceUserSubscription exposing (groupBookmarkedDecoder, groupUnbookmarkedDecoder)
import Subscription.GroupSubscription
    exposing
        ( GroupMembershipUpdatedPayload
        , groupUpdatedDecoder
        , postCreatedDecoder
        , groupMembershipUpdatedDecoder
        )
import Subscription.PostSubscription exposing (replyCreatedDecoder)


-- TYPES


type Event
    = GroupBookmarked Group
    | GroupUnbookmarked Group
    | PostCreated Post
    | GroupMembershipUpdated GroupMembershipUpdatedPayload
    | GroupUpdated Group
    | ReplyCreated Reply
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
        , Decode.map GroupMembershipUpdated groupMembershipUpdatedDecoder
        , Decode.map ReplyCreated replyCreatedDecoder
        ]
