module Util
    exposing
        ( Lazy(..)
        , (=>)
        , dateDecoder
        , postWithCsrfToken
        )

import Date exposing (Date)
import Json.Decode as Decode exposing (Decoder, string, andThen, succeed, fail)
import Http


type Lazy a
    = NotLoaded
    | Loaded a



-- SUGAR


(=>) : a -> b -> ( a, b )
(=>) a b =
    ( a, b )



-- CUSTOM DECODERS


{-| Decodes a Date from JSON.

    decodeString dateDecoder "2017-12-28T10:00:00Z"
    -- Ok <Thu Dec 28 2017 10:00:00 GMT>

-}
dateDecoder : Decoder Date
dateDecoder =
    let
        convert : String -> Decoder Date
        convert raw =
            case Date.fromString raw of
                Ok date ->
                    succeed date

                Err error ->
                    fail error
    in
        string |> andThen convert



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
