module NotificationSet exposing
    ( NotificationSet, LoadingState(..)
    , empty, isLoaded, setLoaded
    , add, addMany, removeMany, isEmpty, hasMore, setHasMore, firstOccurredAt, resolve
    )

{-| A NotificationSet represents a list of notifications.


# Types

@docs NotificationSet, LoadingState


# Initialization

@docs empty, isLoaded, setLoaded


# Operations

@docs add, addMany, removeMany, isEmpty, hasMore, setHasMore, firstOccurredAt, resolve

-}

import Id exposing (Id)
import Notification exposing (Notification, State(..))
import Repo exposing (Repo)
import ResolvedNotification exposing (ResolvedNotification)
import Set exposing (Set)
import Time exposing (Posix)



-- TYPES


type NotificationSet
    = NotificationSet Internal


type alias Internal =
    { ids : Set Id
    , state : LoadingState
    , hasMore : Bool
    }


type LoadingState
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
addMany ids (NotificationSet internal) =
    NotificationSet { internal | ids = Set.union internal.ids (Set.fromList ids) }


removeMany : List Id -> NotificationSet -> NotificationSet
removeMany ids (NotificationSet internal) =
    NotificationSet { internal | ids = Set.diff internal.ids (Set.fromList ids) }


isEmpty : NotificationSet -> Bool
isEmpty (NotificationSet internal) =
    Set.isEmpty internal.ids


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


resolve : Repo -> NotificationSet -> List ResolvedNotification
resolve repo (NotificationSet internal) =
    internal.ids
        |> Set.toList
        |> List.filterMap (ResolvedNotification.resolve repo)
        |> sort



-- PRIVATE


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
