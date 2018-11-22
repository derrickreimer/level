module Flash exposing (Flash, Key, Level(..), expire, init, set, startClock)

import Process
import Task exposing (Task)


type Flash
    = Flash Internal


type alias Internal =
    { level : Level
    , text : String
    , duration : Float
    , key : Key
    , state : State
    }


type Key
    = Key Int


type State
    = Inactive
    | ClockNotStarted
    | ClockRunning


type Level
    = Notice
    | Alert



-- API


init : Flash
init =
    Flash
        { level = Notice
        , text = ""
        , duration = 0
        , key = Key 0
        , state = Inactive
        }


set : Level -> String -> Float -> Flash -> Flash
set level text duration (Flash internal) =
    Flash
        { internal
            | level = level
            , text = text
            , duration = duration
            , key = increment internal.key
            , state = ClockNotStarted
        }


startClock : (Key -> msg) -> Flash -> ( Flash, Cmd msg )
startClock toMsg (Flash internal) =
    case internal.state of
        ClockNotStarted ->
            let
                cmd =
                    Process.sleep internal.duration
                        |> Task.perform (\_ -> toMsg internal.key)

                newFlash =
                    Flash { internal | state = ClockRunning }
            in
            ( newFlash, cmd )

        _ ->
            ( Flash internal, Cmd.none )


expire : Key -> Flash -> Flash
expire key (Flash internal) =
    if keysMatch key internal.key then
        Flash { internal | state = Inactive }

    else
        Flash internal



-- PRIVATE


increment : Key -> Key
increment (Key counter) =
    Key (counter + 1)


keysMatch : Key -> Key -> Bool
keysMatch (Key a) (Key b) =
    a == b
