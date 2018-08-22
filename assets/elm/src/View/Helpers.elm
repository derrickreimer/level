module View.Helpers exposing (displayName, formatDateTime, formatTime, onSameDay, selectValue, setFocus, smartFormatDate, unsetFocus, viewIf, viewUnless)

import Browser.Dom exposing (blur, focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Encode as Encode
import Ports
import Task
import Time exposing (Month(..), Posix, Weekday(..), Zone)



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

    formatTime ( zone, posix ) == "9:18 pm"

    TODO: make this represent in am/pm time instead of military time.

-}
formatTime : ( Zone, Posix ) -> String
formatTime ( zone, posix ) =
    let
        ( hour, meridian ) =
            posix
                |> Time.toHour zone
                |> toTwelveHour

        minute =
            posix
                |> Time.toMinute zone
                |> padMinutes
    in
    String.fromInt hour ++ ":" ++ minute ++ " " ++ meridian


{-| Converts a date into a human-friendly date and time string.

    formatDateTime False ( zone, posix ) == "Dec 26 at 11:10 am"

    formatDateTime True ( zone, posix ) == "Dec 26, 2018 at 11:10 am"

-}
formatDateTime : Bool -> ( Zone, Posix ) -> String
formatDateTime withYear ( zone, posix ) =
    let
        month =
            posix
                |> Time.toMonth zone
                |> toShortMonth

        day =
            posix
                |> Time.toDay zone
                |> String.fromInt

        year =
            posix
                |> Time.toYear zone
                |> String.fromInt

        dayString =
            month ++ " " ++ day

        timeString =
            formatTime ( zone, posix )
    in
    if withYear then
        dayString ++ ", " ++ year ++ " at " ++ timeString

    else
        dayString ++ " at " ++ timeString


toShortWeekday : Time.Weekday -> String
toShortWeekday weekday =
    case weekday of
        Mon ->
            "Mon"

        Tue ->
            "Tue"

        Wed ->
            "Wed"

        Thu ->
            "Thu"

        Fri ->
            "Fri"

        Sat ->
            "Sat"

        Sun ->
            "Sun"


toShortMonth : Time.Month -> String
toShortMonth month =
    case month of
        Jan ->
            "Jan"

        Feb ->
            "Feb"

        Mar ->
            "Mar"

        Apr ->
            "Apr"

        May ->
            "May"

        Jun ->
            "Jun"

        Jul ->
            "Jul"

        Aug ->
            "Aug"

        Sep ->
            "Sep"

        Oct ->
            "Oct"

        Nov ->
            "Nov"

        Dec ->
            "Dec"


{-| Checks to see if two dates are on the same day.
-}
onSameDay : ( Zone, Posix ) -> ( Zone, Posix ) -> Bool
onSameDay ( z1, p1 ) ( z2, p2 ) =
    Time.toYear z1 p1
        == Time.toYear z2 p2
        && Time.toMonth z1 p1
        == Time.toMonth z2 p2
        && Time.toDay z1 p1
        == Time.toDay z2 p2


{-| Formats the given date intelligently, relative to the current time.

    smartFormatDate now someTimeToday == "Today at 10:01am"

    smartFormatDate now daysAgo == "May 15 at 5:45pm"

-}
smartFormatDate : ( Zone, Posix ) -> ( Zone, Posix ) -> String
smartFormatDate now date =
    if onSameDay now date then
        "Today at " ++ formatTime date

    else
        formatDateTime False date



-- INTERNAL


padMinutes : Int -> String
padMinutes minutes =
    if minutes < 10 then
        "0" ++ String.fromInt minutes

    else
        String.fromInt minutes


toTwelveHour : Int -> ( Int, String )
toTwelveHour hour =
    if hour == 0 then
        ( 12, "am" )

    else if hour < 12 then
        ( hour, "am" )

    else if hour == 12 then
        ( 12, "pm" )

    else
        ( remainderBy 12 hour, "pm" )
