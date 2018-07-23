module Socket exposing (send, cancel)

import GraphQL exposing (Document, serializeDocument)
import Json.Encode as Encode
import Ports
import Socket.Types exposing (Payload)


-- OUTBOUND


send : String -> Document -> Maybe Encode.Value -> Cmd msg
send clientId document maybeVariables =
    Payload clientId (serializeDocument document) maybeVariables
        |> Ports.sendSocket


cancel : String -> Cmd msg
cancel clientId =
    Ports.cancelSocket clientId
