port module Ports exposing (autosize, cancelSocket, presenceIn, presenceOut, pushManagerIn, pushManagerOut, receiveFile, requestFile, scrollPositionReceived, scrollTo, scrollToBottom, select, sendSocket, socketAbort, socketError, socketResult, socketStart, socketTokenUpdated, updateToken)

import Autosize.Types
import File.Types
import Json.Decode as Decode
import Scroll.Types
import Socket.Types



-- INBOUND


port socketAbort : (Decode.Value -> msg) -> Sub msg


port socketStart : (Decode.Value -> msg) -> Sub msg


port socketResult : (Decode.Value -> msg) -> Sub msg


port socketError : (Decode.Value -> msg) -> Sub msg


port socketTokenUpdated : (Decode.Value -> msg) -> Sub msg


port scrollPositionReceived : (Decode.Value -> msg) -> Sub msg


port receiveFile : (File.Types.Data -> msg) -> Sub msg


port pushManagerIn : (Decode.Value -> msg) -> Sub msg


port presenceIn : (Decode.Value -> msg) -> Sub msg



-- OUTBOUND


port sendSocket : Socket.Types.Payload -> Cmd msg


port cancelSocket : String -> Cmd msg


port updateToken : String -> Cmd msg


port scrollTo : Scroll.Types.AnchorParams -> Cmd msg


port scrollToBottom : Scroll.Types.ContainerParams -> Cmd msg


port autosize : Autosize.Types.Args -> Cmd msg


port select : String -> Cmd msg


port requestFile : String -> Cmd msg


port pushManagerOut : String -> Cmd msg


port presenceOut : { method : String, topic : String } -> Cmd msg
