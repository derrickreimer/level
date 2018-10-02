module View.Helpers exposing (formatTime, formatTimeOfDay, onNonAnchorClick, onSameDay, selectValue, setFocus, smartFormatTime, time, unsetFocus, viewIf, viewUnless)

import Browser.Dom exposing (blur, focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import Task
import Time exposing (Month(..), Posix, Weekday(..), Zone)



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


onNonAnchorClick : msg -> Attribute msg
onNonAnchorClick msg =
    let
        convert nodeName =
            case nodeName of
                "A" ->
                    Decode.fail "a link was clicked"

                "BUTTON" ->
                    Decode.fail "a button was clicked"

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
formatTimeOfDay : ( Zone, Posix ) -> String
formatTimeOfDay ( zone, posix ) =
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

    formatTime False ( zone, posix ) == "Dec 26 at 11:10 am"

    formatTime True ( zone, posix ) == "Dec 26, 2018 at 11:10 am"

-}
formatTime : Bool -> Bool -> ( Zone, Posix ) -> String
formatTime withYear withTime ( zone, posix ) =
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
            formatTimeOfDay ( zone, posix )
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
onSameDay : ( Zone, Posix ) -> ( Zone, Posix ) -> Bool
onSameDay ( z1, p1 ) ( z2, p2 ) =
    Time.toYear z1 p1
        == Time.toYear z2 p2
        && Time.toMonth z1 p1
        == Time.toMonth z2 p2
        && Time.toDay z1 p1
        == Time.toDay z2 p2


{-| Formats the given date intelligently, relative to the current time.

    smartFormatTime now someTimeToday == "Today at 10:01am"

    smartFormatTime now daysAgo == "May 15 at 5:45pm"

-}
smartFormatTime : ( Zone, Posix ) -> ( Zone, Posix ) -> String
smartFormatTime now date =
    if onSameDay now date then
        formatTimeOfDay date

    else
        formatTime False False date


time : ( Zone, Posix ) -> ( Zone, Posix ) -> List (Attribute msg) -> Html msg
time now date attrs =
    let
        fullTime =
            formatTime True True date

        smartTime =
            smartFormatTime now date
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
