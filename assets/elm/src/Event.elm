module Event exposing (Event(..), decodeEvent)

import Json.Decode as Decode
import Data.Group exposing (Group)
import Data.Post exposing (Post)
import Data.Reply exposing (Reply)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Subscription.SpaceSubscription exposing (spaceUpdatedDecoder, spaceUserUpdatedDecoder)
import Subscription.SpaceUserSubscription exposing (groupBookmarkedDecoder, groupUnbookmarkedDecoder)
import Subscription.GroupSubscription exposing (groupUpdatedDecoder, postCreatedDecoder, groupMembershipUpdatedDecoder)
import Subscription.PostSubscription exposing (replyCreatedDecoder)


-- TYPES


type Event
    = GroupBookmarked Group
    | GroupUnbookmarked Group
    | PostCreated Post
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
        , Decode.map GroupMembershipUpdated groupMembershipUpdatedDecoder
        , Decode.map ReplyCreated replyCreatedDecoder
        , Decode.map SpaceUpdated spaceUpdatedDecoder
        , Decode.map SpaceUserUpdated spaceUserUpdatedDecoder
        ]
