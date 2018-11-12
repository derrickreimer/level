module Util exposing (dateDecoder, postWithCsrfToken)

import Http
import Json.Decode as Decode exposing (Decoder, andThen, fail, string, succeed)
import Time exposing (Posix)



-- CUSTOM DECODERS


{-| Decodes a (millisecond) timestamp from JSON.
-}
dateDecoder : Decoder Posix
dateDecoder =
    Decode.int |> andThen (Decode.succeed << Time.millisToPosix)



-- HTTP HELPERS


postWithCsrfToken : String -> String -> Http.Body -> Decode.Decoder a -> Http.Request a
postWithCsrfToken token url body decoder =
    Http.request
        { method = "POST"
        , headers = [ Http.header "X-Csrf-Token" token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
