port module Ports exposing (beaconOut, postEditorIn, postEditorOut, presenceIn, presenceOut, receiveFile, requestFile, scrollPositionReceived, scrollTo, scrollToBottom, select, serviceWorkerIn, serviceWorkerOut, socketIn, socketOut, socketTokenUpdated, updateToken)

import Json.Decode as Decode
import Json.Encode as Encode
import Scroll.Types



-- INBOUND


port socketIn : (Decode.Value -> msg) -> Sub msg


port socketTokenUpdated : (Decode.Value -> msg) -> Sub msg


port scrollPositionReceived : (Decode.Value -> msg) -> Sub msg


port receiveFile : (Decode.Value -> msg) -> Sub msg


port serviceWorkerIn : (Decode.Value -> msg) -> Sub msg


port presenceIn : (Decode.Value -> msg) -> Sub msg


port dragIn : (Decode.Value -> msg) -> Sub msg


port postEditorIn : (Decode.Value -> msg) -> Sub msg



-- OUTBOUND


port beaconOut : Encode.Value -> Cmd msg


port socketOut : Encode.Value -> Cmd msg


port updateToken : String -> Cmd msg


port scrollTo : Scroll.Types.AnchorParams -> Cmd msg


port scrollToBottom : Scroll.Types.ContainerParams -> Cmd msg


port select : String -> Cmd msg


port requestFile : String -> Cmd msg


port serviceWorkerOut : String -> Cmd msg


port presenceOut : Encode.Value -> Cmd msg


port postEditorOut : Encode.Value -> Cmd msg
