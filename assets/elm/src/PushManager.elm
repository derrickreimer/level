module PushManager exposing (Payload(..), decodePayload, decoder, getSubscription, receive, subscribe)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports


type Payload
    = Subscription (Maybe String)
    | Unknown Decode.Value



-- INBOUND


receive : (Decode.Value -> msg) -> Sub msg
receive toMsg =
    Ports.pushManagerIn toMsg



-- OUTBOUND


getSubscription : Cmd msg
getSubscription =
    Ports.pushManagerOut "getSubscription"


subscribe : Cmd msg
subscribe =
    Ports.pushManagerOut "subscribe"



-- DECODING


decodePayload : Encode.Value -> Payload
decodePayload value =
    Decode.decodeValue decoder value
        |> Result.withDefault (Unknown value)


decoder : Decoder Payload
decoder =
    let
        convert type_ =
            case type_ of
                "subscription" ->
                    Decode.map Subscription <|
                        Decode.field "subscription" nullStringDecoder

                _ ->
                    Decode.fail "Push manager payload not recognized"
    in
    Decode.field "type" Decode.string
        |> Decode.andThen convert


nullStringDecoder : Decoder (Maybe String)
nullStringDecoder =
    let
        convert value =
            if value == "null" then
                Nothing

            else
                Just value
    in
    Decode.string
        |> Decode.andThen (Decode.succeed << convert)
