module PageError exposing (PageError(..), mapSessionError)

import Session
import Task exposing (Task)


type PageError
    = NotFound
    | SessionError Session.Error


mapSessionError : Task Session.Error a -> Task PageError a
mapSessionError task =
    Task.mapError SessionError task
