module TimeWithZone exposing (TimeWithZone, getPosix, getZone, init, now, setPosix, setZone, toDay, toHour, toMillis, toMinute, toMonth, toSecond, toWeekday, toYear)

import Task exposing (Task)
import Time exposing (Posix, Zone)


type TimeWithZone
    = TimeWithZone Internal


type alias Internal =
    { zone : Zone
    , posix : Posix
    }


init : Zone -> Posix -> TimeWithZone
init zone posix =
    TimeWithZone (Internal zone posix)


now : Task x TimeWithZone
now =
    Task.map2 init Time.here Time.now


getPosix : TimeWithZone -> Posix
getPosix (TimeWithZone internal) =
    internal.posix


getZone : TimeWithZone -> Zone
getZone (TimeWithZone internal) =
    internal.zone


setPosix : Posix -> TimeWithZone -> TimeWithZone
setPosix newPosix (TimeWithZone internal) =
    TimeWithZone { internal | posix = newPosix }


setZone : Zone -> TimeWithZone -> TimeWithZone
setZone newZone (TimeWithZone internal) =
    TimeWithZone { internal | zone = newZone }


toYear : TimeWithZone -> Int
toYear time =
    Time.toYear (getZone time) (getPosix time)


toMonth : TimeWithZone -> Time.Month
toMonth time =
    Time.toMonth (getZone time) (getPosix time)


toDay : TimeWithZone -> Int
toDay time =
    Time.toDay (getZone time) (getPosix time)


toWeekday : TimeWithZone -> Time.Weekday
toWeekday time =
    Time.toWeekday (getZone time) (getPosix time)


toHour : TimeWithZone -> Int
toHour time =
    Time.toHour (getZone time) (getPosix time)


toMinute : TimeWithZone -> Int
toMinute time =
    Time.toMinute (getZone time) (getPosix time)


toSecond : TimeWithZone -> Int
toSecond time =
    Time.toSecond (getZone time) (getPosix time)


toMillis : TimeWithZone -> Int
toMillis time =
    Time.toMillis (getZone time) (getPosix time)
