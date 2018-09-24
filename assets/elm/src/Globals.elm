module Globals exposing (Globals)

import NewRepo exposing (NewRepo)
import Session exposing (Session)


type alias Globals =
    { session : Session
    , newRepo : NewRepo
    }
