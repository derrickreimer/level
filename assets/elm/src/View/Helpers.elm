module View.Helpers exposing (formatTime, formatTimeOfDay, onPassiveClick, onSameDay, selectValue, setFocus, smartFormatTime, timeTag, unsetFocus, viewIf, viewUnless)

import Browser.Dom exposing (blur, focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Task
import Time exposing (Month(..), Posix, Weekday(..), Zone)
import TimeWithZone exposing (TimeWithZone)



-- TYPES


type alias Nameable a =
    { a | firstName : String, lastName : String }



-- MISC


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



-- EVENTS


onPassiveClick : msg -> Attribute msg
onPassiveClick msg =
    let
        convert nodeName =
            case nodeName of
                "A" ->
                    Decode.fail "a link was clicked"

                "BUTTON" ->
                    Decode.fail "a button was clicked"

                "LABEL" ->
                    Decode.fail "a label was clicked"

                "TEXTAREA" ->
                    Decode.fail "a textarea was clicked"

                "INPUT" ->
                    Decode.fail "an input was clicked"

                _ ->
                    Decode.succeed msg

        decoder =
            Decode.at [ "target", "nodeName" ] Decode.string
                |> Decode.andThen convert
    in
    on "click" decoder



-- DATE HELPERS


{-| Converts a date into a human-friendly HH:MM PP time string.

    formatTimeOfDay ( zone, posix ) == "9:18 pm"

    TODO: make this represent in am/pm time instead of military time.

-}
formatTimeOfDay : TimeWithZone -> String
formatTimeOfDay time =
    let
        ( hour, meridian ) =
            time
                |> TimeWithZone.toHour
                |> toTwelveHour

        minute =
            time
                |> TimeWithZone.toMinute
                |> padMinutes
    in
    String.fromInt hour ++ ":" ++ minute ++ " " ++ meridian


{-| Converts a date into a human-friendly date and time string.

    formatTime False time == "Dec 26 at 11:10 am"

    formatTime True time == "Dec 26, 2018 at 11:10 am"

-}
formatTime : Bool -> Bool -> TimeWithZone -> String
formatTime withYear withTime time =
    let
        month =
            time
                |> TimeWithZone.toMonth
                |> toShortMonth

        day =
            time
                |> TimeWithZone.toDay
                |> String.fromInt

        year =
            time
                |> TimeWithZone.toYear
                |> String.fromInt

        dayString =
            month ++ " " ++ day

        timeString =
            formatTimeOfDay time
    in
    dayString
        |> appendIf withYear (", " ++ year)
        |> appendIf withTime (" at " ++ timeString)


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
onSameDay : TimeWithZone -> TimeWithZone -> Bool
onSameDay t1 t2 =
    TimeWithZone.toYear t1
        == TimeWithZone.toYear t2
        && TimeWithZone.toMonth t1
        == TimeWithZone.toMonth t2
        && TimeWithZone.toDay t1
        == TimeWithZone.toDay t2


{-| Formats the given date intelligently, relative to the current time.

    smartFormatTime now someTimeToday == "Today at 10:01am"

    smartFormatTime now daysAgo == "May 15 at 5:45pm"

-}
smartFormatTime : TimeWithZone -> TimeWithZone -> String
smartFormatTime now time =
    if onSameDay now time then
        formatTimeOfDay time

    else
        formatTime False False time


timeTag : TimeWithZone -> TimeWithZone -> List (Attribute msg) -> Html msg
timeTag now time attrs =
    let
        fullTime =
            formatTime True True time

        smartTime =
            smartFormatTime now time
    in
    Html.time ([ rel "tooltip", title fullTime ] ++ attrs) [ text smartTime ]



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


appendIf : Bool -> String -> String -> String
appendIf truth postfix string =
    if truth then
        string ++ postfix

    else
        string
