module Socket exposing (Message(..), decodeMessage, decoder, receive, send)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports


type Message
    = Event Decode.Value
    | Unknown



-- INBOUND


receive : (Decode.Value -> msg) -> Sub msg
receive toMsg =
    Ports.socketIn toMsg


decoder : Decoder Message
decoder =
    let
        convert type_ =
            case type_ of
                "event" ->
                    Decode.map Event (Decode.field "data" Decode.value)

                _ ->
                    Decode.fail "message not recognized"
    in
    Decode.field "type" Decode.string
        |> Decode.andThen convert


decodeMessage : Decode.Value -> Message
decodeMessage value =
    Decode.decodeValue decoder value
        |> Result.withDefault Unknown



-- OUTBOUND


send : Encode.Value -> Cmd msg
send data =
    Ports.socketOut data
