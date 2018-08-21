module TaskHelpers exposing (andThenGetCurrentTime)

import Task exposing (Task)
import Time exposing (Posix, Zone)



-- API


andThenGetCurrentTime : Task x a -> Task x ( a, ( Zone, Posix ) )
andThenGetCurrentTime task =
    Task.map3 (\res zone now -> ( res, ( zone, now ) )) task Time.here Time.now
