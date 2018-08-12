module TaskHelpers exposing (andThenGetCurrentTime)

import Date exposing (Date)
import Task exposing (Task)


-- API


andThenGetCurrentTime : Task x a -> Task x ( a, Date )
andThenGetCurrentTime task =
    let
        dateTask : a -> Task x ( a, Date )
        dateTask result =
            Date.now
                |> Task.map (\now -> ( result, now ))
    in
        task
            |> Task.andThen dateTask
