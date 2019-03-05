module NotificationSet exposing
    ( NotificationSet, State(..)
    , empty, isLoaded, setLoaded
    , add, hasUndismissed, resolve, hasMore, setHasMore, firstOccurredAt
    , addMany
    )

{-| A NotificationSet represents a list of notifications.


# Types

@docs NotificationSet, State


# Initialization

@docs empty, isLoaded, setLoaded


# Operations

@docs add, hasUndismissed, resolve, hasMore, setHasMore, firstOccurredAt

-}

import Id exposing (Id)
import Notification exposing (Notification)
import Repo exposing (Repo)
import ResolvedNotification exposing (ResolvedNotification)
import Set exposing (Set)
import Time exposing (Posix)



-- TYPES


type NotificationSet
    = NotificationSet Internal


type alias Internal =
    { ids : Set Id
    , state : State
    , hasMore : Bool
    }


type State
    = Loading
    | Loaded



-- INITIALIZATION


empty : NotificationSet
empty =
    NotificationSet (Internal Set.empty Loading False)


isLoaded : NotificationSet -> Bool
isLoaded (NotificationSet internal) =
    internal.state == Loaded


setLoaded : NotificationSet -> NotificationSet
setLoaded (NotificationSet internal) =
    NotificationSet { internal | state = Loaded }



-- OPERATIONS


add : Id -> NotificationSet -> NotificationSet
add id (NotificationSet internal) =
    NotificationSet { internal | ids = Set.insert id internal.ids }


addMany : List Id -> NotificationSet -> NotificationSet
addMany ids notifications =
    List.foldr add notifications ids


hasUndismissed : Repo -> NotificationSet -> Bool
hasUndismissed repo set =
    set
        |> resolveUnsorted repo
        |> List.filter (Notification.withUndismissed << .notification)
        |> (not << List.isEmpty)


resolve : Repo -> NotificationSet -> List ResolvedNotification
resolve repo set =
    set
        |> resolveUnsorted repo
        |> sort


hasMore : NotificationSet -> Bool
hasMore (NotificationSet internal) =
    internal.hasMore


setHasMore : Bool -> NotificationSet -> NotificationSet
setHasMore truth (NotificationSet internal) =
    NotificationSet { internal | hasMore = truth }


firstOccurredAt : Repo -> NotificationSet -> Maybe Posix
firstOccurredAt repo set =
    set
        |> resolve repo
        |> List.reverse
        |> List.head
        |> Maybe.map (Notification.occurredAt << .notification)



-- PRIVATE


resolveUnsorted : Repo -> NotificationSet -> List ResolvedNotification
resolveUnsorted repo (NotificationSet internal) =
    internal.ids
        |> Set.toList
        |> List.filterMap (ResolvedNotification.resolve repo)


sort : List ResolvedNotification -> List ResolvedNotification
sort resolvedNotifications =
    let
        sorter a b =
            case compare (toOccurredAtMillis a) (toOccurredAtMillis b) of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT
    in
    resolvedNotifications
        |> List.sortWith sorter


toOccurredAtMillis : ResolvedNotification -> Int
toOccurredAtMillis resolvedNotification =
    resolvedNotification
        |> .notification
        |> Notification.occurredAt
        |> Time.posixToMillis
