module Globals exposing (Globals)

import Repo exposing (Repo)
import Session exposing (Session)


type alias Globals =
    { session : Session
    , repo : Repo
    }
