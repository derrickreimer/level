module ServiceWorker exposing (Payload(..), decodePayload, decoder, getPushSubscription, pushSubscribe, receive)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports


type Payload
    = PushSubscription (Maybe String)
    | Redirect String
    | Unknown Decode.Value



-- INBOUND


receive : (Decode.Value -> msg) -> Sub msg
receive toMsg =
    Ports.serviceWorkerIn toMsg



-- OUTBOUND


getPushSubscription : Cmd msg
getPushSubscription =
    Ports.serviceWorkerOut "getPushSubscription"


pushSubscribe : Cmd msg
pushSubscribe =
    Ports.serviceWorkerOut "pushSubscribe"



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
                "pushSubscription" ->
                    Decode.map PushSubscription <|
                        Decode.field "subscription" nullStringDecoder

                "redirect" ->
                    Decode.map Redirect <|
                        Decode.field "url" Decode.string

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
