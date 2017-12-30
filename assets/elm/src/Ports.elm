port module Ports exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode


-- INBOUND


type alias ScrollPosition =
    { containerId : String
    , fromTop : Int
    , fromBottom : Int
    , anchorOffset : Maybe Int
    }


scrollPositionDecoder : Decode.Decoder ScrollPosition
scrollPositionDecoder =
    Decode.map4 ScrollPosition
        (Decode.field "containerId" Decode.string)
        (Decode.field "fromTop" Decode.int)
        (Decode.field "fromBottom" Decode.int)
        (Decode.field "anchorOffset" (Decode.maybe Decode.int))


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
    , anchorId : String
    , offset : Int
    }


type alias ScrollPositionArgs =
    { containerId : String
    , anchorId : Maybe String
    }


port sendFrame : Frame -> Cmd msg


port getScrollPosition : ScrollPositionArgs -> Cmd msg


port scrollTo : ScrollParams -> Cmd msg
