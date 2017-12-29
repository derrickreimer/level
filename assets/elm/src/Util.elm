module Util exposing (..)

import Date exposing (Date)
import Date.Format
import Json.Decode exposing (Decoder, string, andThen, succeed, fail)


-- LIST HELPERS


{-| Gets the last item from a list.

    last [1, 2, 3] == Just 3
    last [] == Nothing

-}
last : List a -> Maybe a
last =
    List.foldl (Just >> always) Nothing



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



-- DATE HELPERS


{-| Converts a Time into a human-friendly HH:MMam time string.

    formatTime (Date ...) == "9:18 pm"

-}
formatTime : Date -> String
formatTime date =
    Date.Format.format "%-l:%M %P" date


{-| Converts a Time into a human-friendly date and time string.

    formatDateTime (Date ...) == "Dec 26, 2017 at 11:10 am"

-}
formatDateTime : Date -> String
formatDateTime date =
    Date.Format.format "%b %-e, %Y" date ++ " at " ++ formatTime date


{-| Converts a Time into a human-friendly day string.

    formatDateTime (Date ...) == "Wed, December 26, 2017"

-}
formatDay : Date -> String
formatDay date =
    Date.Format.format "%A, %B %-e, %Y" date


{-| Checks to see if two dates are on the same day.
-}
onSameDay : Date -> Date -> Bool
onSameDay d1 d2 =
    Date.year d1
        == Date.year d2
        && Date.month d1
        == Date.month d2
        && Date.day d1
        == Date.day d2
