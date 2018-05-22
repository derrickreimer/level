module Event exposing (Event(..), decodeEvent)

import Json.Decode as Decode
import Subscription.GroupBookmarked
import Subscription.GroupUnbookmarked
import Subscription.PostCreated


-- TYPES


type Event
    = GroupBookmarked Subscription.GroupBookmarked.Data
    | GroupUnbookmarked Subscription.GroupUnbookmarked.Data
    | PostCreated Subscription.PostCreated.Data
    | Unknown



-- DECODER


decodeEvent : Decode.Value -> Event
decodeEvent value =
    Decode.decodeValue eventDecoder value
        |> Result.withDefault Unknown


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.oneOf
        [ Decode.map GroupBookmarked Subscription.GroupBookmarked.decoder
        , Decode.map GroupUnbookmarked Subscription.GroupUnbookmarked.decoder
        , Decode.map PostCreated Subscription.PostCreated.decoder
        ]
