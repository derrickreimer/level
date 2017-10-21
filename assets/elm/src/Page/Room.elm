module Page.Room exposing (Model, makeRequest)

{-| Viewing an particular room.
-}

import Task exposing (Task)
import Http
import Data.Room exposing (Room)
import Data.Session exposing (Session)
import Query.Room


-- MODEL


type alias Model =
    { room : Room
    }



-- init : Session -> String ->


makeRequest : Session -> String -> Task Http.Error Query.Room.Response
makeRequest session slug =
    Http.toTask (Query.Room.request session.apiToken (Query.Room.Params slug))



-- UPDATE
-- VIEW
