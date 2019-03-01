module Globals exposing (Globals)

import Browser.Navigation as Nav
import Device exposing (Device)
import Flash exposing (Flash)
import PushStatus exposing (PushStatus)
import Repo exposing (Repo)
import Route exposing (Route)
import Session exposing (Session)


type alias Globals =
    { session : Session
    , repo : Repo
    , navKey : Nav.Key
    , timeZone : String
    , flash : Flash
    , device : Device
    , pushStatus : PushStatus
    , currentRoute : Maybe Route
    , showKeyboardCommands : Bool
    , hasNotifications : Bool
    , showNotifications : Bool
    }
