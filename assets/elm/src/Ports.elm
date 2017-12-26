port module Ports exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode


-- INBOUND


type alias ScrollPosition =
    { id : String
    , fromTop : Int
    , fromBottom : Int
    }


scrollPositionDecoder : Decode.Decoder ScrollPosition
scrollPositionDecoder =
    Decode.map3 ScrollPosition
        (Decode.field "id" Decode.string)
        (Decode.field "fromTop" Decode.int)
        (Decode.field "fromBottom" Decode.int)


port startFrameReceived : (Decode.Value -> msg) -> Sub msg


port resultFrameReceived : (Decode.Value -> msg) -> Sub msg


port scrollPositionReceived : (Decode.Value -> msg) -> Sub msg



-- OUTBOUND


type alias Frame =
    { operation : String
    , variables : Maybe Encode.Value
    }


type alias ScrollParams =
    { containerId : String
    , childId : String
    , offset : Int
    }


port sendFrame : Frame -> Cmd msg


port getScrollPosition : String -> Cmd msg


port scrollTo : ScrollParams -> Cmd msg
