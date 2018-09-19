module Globals exposing (Globals)

import NewRepo exposing (NewRepo)
import Repo exposing (Repo)
import Session exposing (Session)


type alias Globals =
    { session : Session
    , repo : Repo
    , newRepo : NewRepo
    }
