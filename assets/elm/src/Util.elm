module Util exposing (..)

import Date exposing (Date)
import Json.Decode exposing (Decoder, string, andThen, succeed, fail)


-- UTILITY FUNCTIONS


{-| Gets the last item from a list.

    last [1, 2, 3] == Just 3
    last [] == Nothing

-}
last : List a -> Maybe a
last =
    List.foldl (Just >> always) Nothing


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
