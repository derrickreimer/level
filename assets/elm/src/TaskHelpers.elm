module TaskHelpers exposing (andThenGetCurrentTime, getCurrentTime)

import Task exposing (Task)
import Time exposing (Posix, Zone)



-- API


getCurrentTime : Task x ( Zone, Posix )
getCurrentTime =
    Task.map2 Tuple.pair Time.here Time.now


andThenGetCurrentTime : Task x a -> Task x ( a, ( Zone, Posix ) )
andThenGetCurrentTime task =
    Task.map3 (\res zone now -> ( res, ( zone, now ) )) task Time.here Time.now
