module TaskHelpers exposing (andThenGetCurrentTime)

import Task exposing (Task)
import Time exposing (Posix, Zone)
import TimeWithZone exposing (TimeWithZone)



-- API


andThenGetCurrentTime : Task x a -> Task x ( a, TimeWithZone )
andThenGetCurrentTime task =
    Task.map2 (\res now -> ( res, now )) task TimeWithZone.now
