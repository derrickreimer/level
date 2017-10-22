module Page.Room exposing (Model, fetchRoom)

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


{-| Build a task to fetch a room by slug.
-}
fetchRoom : Session -> String -> Task Http.Error Query.Room.Response
fetchRoom session slug =
    Query.Room.request session.apiToken (Query.Room.Params slug)
        |> Http.toTask



-- UPDATE
-- VIEW
