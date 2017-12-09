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


port startFrames : (Decode.Value -> msg) -> Sub msg


port resultFrames : (Decode.Value -> msg) -> Sub msg


port scrollPosition : (Decode.Value -> msg) -> Sub msg



-- OUTBOUND


type alias Frame =
    { operation : String
    , variables : Maybe Encode.Value
    }


port sendFrame : Frame -> Cmd msg


port getScrollPosition : String -> Cmd msg
