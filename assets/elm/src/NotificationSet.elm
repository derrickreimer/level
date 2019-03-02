module NotificationSet exposing
    ( NotificationSet, State(..)
    , empty, load, isLoaded, setLoaded
    , add, hasUndismissed, resolve
    )

{-| A NotificationSet represents a list of notifications.


# Types

@docs NotificationSet, State


# Initialization

@docs empty, load, isLoaded, setLoaded


# Operations

@docs add, hasUndismissed, resolve

-}

import Id exposing (Id)
import Notification exposing (Notification)
import Repo exposing (Repo)
import ResolvedNotification exposing (ResolvedNotification)



-- TYPES


type NotificationSet
    = NotificationSet Internal


type alias Internal =
    { ids : List Id
    , state : State
    , hasMore : Bool
    }


type State
    = Loading
    | Loaded



-- INITIALIZATION


empty : NotificationSet
empty =
    NotificationSet (Internal [] Loading False)


load : List Id -> NotificationSet -> NotificationSet
load ids (NotificationSet internal) =
    NotificationSet { internal | ids = ids, state = Loaded }


isLoaded : NotificationSet -> Bool
isLoaded (NotificationSet internal) =
    internal.state == Loaded


setLoaded : NotificationSet -> NotificationSet
setLoaded (NotificationSet internal) =
    NotificationSet { internal | state = Loaded }



-- OPERATIONS


add : Id -> NotificationSet -> NotificationSet
add id (NotificationSet internal) =
    NotificationSet { internal | ids = id :: internal.ids }


hasUndismissed : Repo -> NotificationSet -> Bool
hasUndismissed repo (NotificationSet internal) =
    repo
        |> Repo.getNotifications internal.ids
        |> List.filter Notification.withUndismissed
        |> (not << List.isEmpty)


resolve : Repo -> NotificationSet -> List ResolvedNotification
resolve repo (NotificationSet internal) =
    internal.ids
        |> List.filterMap (ResolvedNotification.resolve repo)
