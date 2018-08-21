module View.Helpers exposing
    ( -- MISC
      displayName
    , formatDateTime
    , formatDay
    , formatTime
    , formatTimeWithoutMeridian
    , injectHtml
    , isOverOneYearAgo
    , onSameDay
    , selectValue
      -- DATE HELPERS
    , setFocus
    , smartFormatDate
    , unsetFocus
    , viewIf
    , viewUnless
      -- DOM
    )

import Browser.Dom exposing (blur, focus)
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Encode as Encode
import Ports
import Task
import Time
import Vendor.Date.Format



-- TYPES


type alias Nameable a =
    { a | firstName : String, lastName : String }



-- MISC


{-| Generate the display name for a given user.

    displayName { firstName = "Derrick", lastName = "Reimer" } == "Derrick Reimer"

-}
displayName : Nameable a -> String
displayName nameable =
    nameable.firstName ++ " " ++ nameable.lastName


{-| Inject a raw string of HTML into a div.
-}
injectHtml : List (Attribute msg) -> String -> Html msg
injectHtml attrs rawHtml =
    div (attrs ++ [ property "innerHTML" <| Encode.string rawHtml ]) []


{-| Render the given HTML if the truth value is true.
-}
viewIf : Bool -> Html msg -> Html msg
viewIf truth view =
    if truth == True then
        view

    else
        text ""


{-| Render the given HTML if the truth value is false.
-}
viewUnless : Bool -> Html msg -> Html msg
viewUnless truth view =
    if truth == False then
        view

    else
        text ""



-- DOM


setFocus : String -> msg -> Cmd msg
setFocus id msg =
    Task.attempt (always msg) <| focus id


unsetFocus : String -> msg -> Cmd msg
unsetFocus id msg =
    Task.attempt (always msg) <| blur id


selectValue : String -> Cmd msg
selectValue id =
    Ports.select id



-- DATE HELPERS


{-| Converts a date into a human-friendly HH:MM PP time string.

    formatTime (Date ...) == "9:18 pm"

-}
formatTime : Date -> String
formatTime date =
    Vendor.Date.Format.format "%-l:%M %P" date


{-| Converts a date into a human-friendly HH:MM time string.

    formatTime (Date ...) == "9:18"

-}
formatTimeWithoutMeridian : Date -> String
formatTimeWithoutMeridian date =
    Vendor.Date.Format.format "%-l:%M" date


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
    Vendor.Date.Format.format dateString date ++ " at " ++ formatTime date


{-| Converts a date into a human-friendly day string.

    formatDay (Date ...) == "Wed, December 26, 2017"

-}
formatDay : Date -> String
formatDay date =
    Vendor.Date.Format.format "%A, %B %-e, %Y" date


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
    Date.toTime now - Date.toTime pastDate > (Time.hour * 24 * 365)


{-| Formats the given date intelligently, relative to the current time.

    smartFormatDate now someTimeToday == "Today at 10:01am"

    smartFormatDate now daysAgo == "May 15 at 5:45pm"

    smartFormatDate now overOneYearAgo == "May 10, 2017 at 4:45pm"

-}
smartFormatDate : Date -> Date -> String
smartFormatDate now date =
    if onSameDay now date then
        "Today at " ++ formatTime date

    else if isOverOneYearAgo now date then
        formatDateTime True date

    else
        formatDateTime False date
