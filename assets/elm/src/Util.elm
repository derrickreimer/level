module Util
    exposing
        ( Lazy(..)
        , dateDecoder
        , formatTime
        , formatTimeWithoutMeridian
        , formatDateTime
        , formatDay
        , onSameDay
        , isOverOneYearAgo
        , smartFormatDate
        , postWithCsrfToken
        , displayName
        , injectHtml
        )

import Date exposing (Date)
import Date.Format
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, string, andThen, succeed, fail)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Time


type Lazy a
    = NotLoaded
    | Loaded a


type alias Nameable a =
    { a | firstName : String, lastName : String }



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


{-| Converts a date into a human-friendly HH:MM PP time string.

    formatTime (Date ...) == "9:18 pm"

-}
formatTime : Date -> String
formatTime date =
    Date.Format.format "%-l:%M %P" date


{-| Converts a date into a human-friendly HH:MM time string.

    formatTime (Date ...) == "9:18"

-}
formatTimeWithoutMeridian : Date -> String
formatTimeWithoutMeridian date =
    Date.Format.format "%-l:%M" date


{-| Converts a date into a human-friendly date and time string.

    formatDateTime False (Date ...) == "Dec 26 at 11:10 am"
    formatDateTime True (Date ...) == "Dec 26, 2018 at 11:10 am"

-}
formatDateTime : Bool -> Date -> String
formatDateTime withYear date =
    let
        dateString =
            if withYear then
                "%b %-e, %Y"
            else
                "%b %-e"
    in
        Date.Format.format dateString date ++ " at " ++ formatTime date


{-| Converts a date into a human-friendly day string.

    formatDay (Date ...) == "Wed, December 26, 2017"

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


{-| Checks to see if two days are further than one year apart.
-}
isOverOneYearAgo : Date -> Date -> Bool
isOverOneYearAgo now pastDate =
    (Date.toTime now) - (Date.toTime pastDate) > (Time.hour * 24 * 365)


{-| Formats the given date intelligently, relative to the current time.

    smartFormatDate now someTimeToday == "Today at 10:01am"
    smartFormatDate now daysAgo == "May 15 at 5:45pm"
    smartFormatDate now overOneYearAgo == "May 10, 2017 at 4:45pm"

-}
smartFormatDate : Date -> Date -> String
smartFormatDate now date =
    if onSameDay now date then
        "Today at " ++ (formatTime date)
    else if isOverOneYearAgo now date then
        formatDateTime True date
    else
        formatDateTime False date



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



-- MISC


{-| Generate the display name for a given user.

    displayName { firstName = "Derrick", lastName = "Reimer" } == "Derrick Reimer"

-}
displayName : Nameable a -> String
displayName nameable =
    nameable.firstName ++ " " ++ nameable.lastName


{-| Inject a raw string of HTML into a div.
-}
injectHtml : String -> Html msg
injectHtml rawHtml =
    div [ property "innerHTML" <| Encode.string rawHtml ] []
