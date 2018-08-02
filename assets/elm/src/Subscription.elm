module Subscription exposing (decoder)

import Json.Decode as Decode exposing (Decoder)


-- HELPERS


decoder : String -> String -> String -> Decoder a -> Decoder a
decoder topic event nodeType decoder =
    let
        payloadDecoder typename =
            if typename == (event ++ "Payload") then
                Decode.field nodeType decoder
            else
                Decode.fail "payload does not match"
    in
        Decode.at [ "data", (topic ++ "Subscription") ] <|
            (Decode.field "__typename" Decode.string
                |> Decode.andThen payloadDecoder
            )
