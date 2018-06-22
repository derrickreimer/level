port module Ports exposing (..)

import Json.Decode as Decode
import Autosize
import Socket


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


port socketAbort : (Decode.Value -> msg) -> Sub msg


port socketStart : (Decode.Value -> msg) -> Sub msg


port socketResult : (Decode.Value -> msg) -> Sub msg


port socketError : (Decode.Value -> msg) -> Sub msg


port socketTokenUpdated : (Decode.Value -> msg) -> Sub msg


port scrollPositionReceived : (Decode.Value -> msg) -> Sub msg



-- OUTBOUND


type alias ScrollParams =
    { containerId : String
    , anchorId : String
    , offset : Int
    }


type alias ScrollPositionArgs =
    { containerId : String
    , anchorId : Maybe String
    }


port push : Socket.Payload -> Cmd msg


port cancel : String -> Cmd msg


port updateToken : String -> Cmd msg


port getScrollPosition : ScrollPositionArgs -> Cmd msg


port scrollTo : ScrollParams -> Cmd msg


port autosize : Autosize.Args -> Cmd msg


port select : String -> Cmd msg
