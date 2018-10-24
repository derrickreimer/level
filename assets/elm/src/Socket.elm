module Socket exposing (Event(..), decodeEvent, decoder, receive, send)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports


type Event
    = MessageReceived Decode.Value
    | Opened
    | Closed
    | Unknown



-- INBOUND


receive : (Decode.Value -> msg) -> Sub msg
receive toMsg =
    Ports.socketIn toMsg


decoder : Decoder Event
decoder =
    let
        convert type_ =
            case type_ of
                "message" ->
                    Decode.map MessageReceived (Decode.field "data" Decode.value)

                "opened" ->
                    Decode.succeed Opened

                "closed" ->
                    Decode.succeed Closed

                _ ->
                    Decode.fail "message not recognized"
    in
    Decode.field "type" Decode.string
        |> Decode.andThen convert


decodeEvent : Decode.Value -> Event
decodeEvent value =
    Decode.decodeValue decoder value
        |> Result.withDefault Unknown



-- OUTBOUND


send : Encode.Value -> Cmd msg
send data =
    Ports.socketOut data
