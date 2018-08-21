module Socket exposing (cancel, listen, send)

import GraphQL exposing (Document, serializeDocument)
import Json.Decode exposing (Value)
import Json.Encode as Encode
import Ports
import Socket.Types exposing (Payload)



-- INBOUND


listen : (Value -> msg) -> (Value -> msg) -> (Value -> msg) -> (Value -> msg) -> Sub msg
listen toAbortMsg toStartMsg toResultMsg toErrorMsg =
    Sub.batch
        [ Ports.socketAbort toAbortMsg
        , Ports.socketStart toStartMsg
        , Ports.socketResult toResultMsg
        , Ports.socketError toErrorMsg
        ]



-- OUTBOUND


send : String -> Document -> Maybe Encode.Value -> Cmd msg
send clientId document maybeVariables =
    Payload clientId (serializeDocument document) maybeVariables
        |> Ports.sendSocket


cancel : String -> Cmd msg
cancel clientId =
    Ports.cancelSocket clientId
