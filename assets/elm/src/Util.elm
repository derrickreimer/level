module Util exposing (..)

import Date exposing (Date)
import Date.Format
import Json.Decode as Decode exposing (Decoder, string, andThen, succeed, fail)
import Html exposing (Attribute)
import Html.Events exposing (defaultOptions, onWithOptions)


-- LIST HELPERS


{-| Gets the last item from a list.

    last [1, 2, 3] == Just 3
    last [] == Nothing

-}
last : List a -> Maybe a
last =
    List.foldl (Just >> always) Nothing


{-| Computes the size of a list.

    size [1,2,3] == 3
    size [] == 0

-}
size : List a -> Int
size =
    List.foldl (\_ t -> t + 1) 0



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


{-| Converts a Time into a human-friendly HH:MM PP time string.

    formatTime (Date ...) == "9:18 pm"

-}
formatTime : Date -> String
formatTime date =
    Date.Format.format "%-l:%M %P" date


{-| Converts a Time into a human-friendly HH:MM time string.

    formatTime (Date ...) == "9:18"

-}
formatTimeWithoutMeridian : Date -> String
formatTimeWithoutMeridian date =
    Date.Format.format "%-l:%M" date


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



-- CUSTOM HTML EVENTS


onEnter : msg -> Attribute msg
onEnter msg =
    let
        options =
            { defaultOptions | preventDefault = True }

        codeAndShift : Decode.Decoder ( Int, Bool )
        codeAndShift =
            Decode.map2 (\a b -> ( a, b ))
                Html.Events.keyCode
                (Decode.field "shiftKey" Decode.bool)

        isEnter : ( Int, Bool ) -> Decode.Decoder msg
        isEnter ( code, shiftKey ) =
            if code == 13 && shiftKey == False then
                Decode.succeed msg
            else
                Decode.fail "not ENTER"
    in
        onWithOptions "keydown" options (Decode.andThen isEnter codeAndShift)
