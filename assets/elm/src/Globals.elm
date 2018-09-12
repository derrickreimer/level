module Globals exposing (Globals, request)

import Http
import Repo exposing (Repo)
import Session exposing (Session)
import Task exposing (Task)


type alias Globals =
    { session : Session
    , repo : Repo
    }



-- REQUESTS


request : Globals -> (a -> Repo -> Repo) -> (Session -> Http.Request a) -> Task Session.Error ( Globals, a )
request globals repoUpdater innerRequest =
    Session.request globals.session innerRequest
        |> Task.andThen (updateRepo globals repoUpdater)


updateRepo : Globals -> (a -> Repo -> Repo) -> ( Session, a ) -> Task Session.Error ( Globals, a )
updateRepo globals repoUpdater ( newSession, response ) =
    let
        newGlobals =
            { globals
                | session = newSession
                , repo = repoUpdater response globals.repo
            }
    in
    Task.succeed ( newGlobals, response )
