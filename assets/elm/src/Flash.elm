module Flash exposing (Flash, Key, Level(..), expire, init, set, startTimer, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Process
import Task exposing (Task)


type Flash
    = Flash Internal


type alias Internal =
    { level : Level
    , value : String
    , duration : Float
    , key : Key
    , state : State
    }


type Key
    = Key Int


type State
    = Inactive
    | TimerStopped
    | TimerStarted


type Level
    = Notice
    | Alert



-- API


init : Flash
init =
    Flash
        { level = Notice
        , value = ""
        , duration = 0
        , key = Key 0
        , state = Inactive
        }


set : Level -> String -> Float -> Flash -> Flash
set level value duration (Flash internal) =
    Flash
        { internal
            | level = level
            , value = value
            , duration = duration
            , key = increment internal.key
            , state = TimerStopped
        }


startTimer : (Key -> msg) -> Flash -> ( Flash, Cmd msg )
startTimer toMsg (Flash internal) =
    case internal.state of
        TimerStopped ->
            let
                cmd =
                    Process.sleep internal.duration
                        |> Task.perform (\_ -> toMsg internal.key)

                newFlash =
                    Flash { internal | state = TimerStarted }
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



-- VIEW


view : Flash -> Html msg
view (Flash internal) =
    div
        [ classList
            [ ( "flash font-sans font-antialised fixed px-3 pin-t pin-l-50 z-50", True )
            , ( "hidden", internal.state /= TimerStarted )
            , ( "block", internal.state == TimerStarted )
            ]
        ]
        [ div
            [ classList
                [ ( "relative px-4 py-2 border-b-3", True )
                , ( "border-green bg-green-lightest text-green-dark", internal.level == Notice )
                , ( "border-red bg-red-lightest text-sm text-red", internal.level == Alert )
                ]
            ]
            [ h2 [ class "font-bold text-base" ] [ text internal.value ]
            ]
        ]



-- PRIVATE


increment : Key -> Key
increment (Key counter) =
    Key (counter + 1)


keysMatch : Key -> Key -> Bool
keysMatch (Key a) (Key b) =
    a == b
