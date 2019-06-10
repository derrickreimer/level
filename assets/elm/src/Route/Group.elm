module Route.Group exposing
    ( Params
    , init, getSpaceSlug, getGroupName, getAfter, getBefore, setCursors, getState, setState, getInboxState, setInboxState, getLastActivity, setLastActivity, clearFilters
    , hasSamePath, isEqual
    , parser
    , toString
    )

{-| Route building and parsing for a channel page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getGroupName, getAfter, getBefore, setCursors, getState, setState, getInboxState, setInboxState, getLastActivity, setLastActivity, clearFilters


# Comparison

@docs hasSamePath, isEqual


# Parsing

@docs parser


# Serialization

@docs toString

-}

import InboxStateFilter exposing (InboxStateFilter)
import LastActivityFilter exposing (LastActivityFilter)
import PostStateFilter exposing (PostStateFilter)
import Url.Builder as Builder exposing (QueryParameter, absolute)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string)
import Url.Parser.Query as Query


type Params
    = Params Internal


type alias Internal =
    { spaceSlug : String
    , groupName : String
    , after : Maybe String
    , before : Maybe String
    , state : PostStateFilter
    , inboxState : InboxStateFilter
    , lastActivity : LastActivityFilter
    , plainText : Bool
    }



-- API


init : String -> String -> Params
init spaceSlug groupName =
    Params
        (Internal
            spaceSlug
            groupName
            Nothing
            Nothing
            PostStateFilter.All
            InboxStateFilter.All
            LastActivityFilter.All
            False
        )


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getGroupName : Params -> String
getGroupName (Params internal) =
    internal.groupName


getAfter : Params -> Maybe String
getAfter (Params internal) =
    internal.after


getBefore : Params -> Maybe String
getBefore (Params internal) =
    internal.before


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }


getState : Params -> PostStateFilter
getState (Params internal) =
    internal.state


setState : PostStateFilter -> Params -> Params
setState newState (Params internal) =
    Params { internal | state = newState }


getInboxState : Params -> InboxStateFilter
getInboxState (Params internal) =
    internal.inboxState


setInboxState : InboxStateFilter -> Params -> Params
setInboxState newState (Params internal) =
    Params { internal | inboxState = newState }


getLastActivity : Params -> LastActivityFilter
getLastActivity (Params internal) =
    internal.lastActivity


setLastActivity : LastActivityFilter -> Params -> Params
setLastActivity newState (Params internal) =
    Params { internal | lastActivity = newState }


clearFilters : Params -> Params
clearFilters params =
    params
        |> setCursors Nothing Nothing
        |> setLastActivity LastActivityFilter.All
        |> setState PostStateFilter.All
        |> setInboxState InboxStateFilter.All



-- COMPARISON


hasSamePath : Params -> Params -> Bool
hasSamePath (Params a) (Params b) =
    a.spaceSlug == b.spaceSlug && a.groupName == b.groupName


isEqual : Params -> Params -> Bool
isEqual (Params a) (Params b) =
    a.spaceSlug
        == b.spaceSlug
        && a.groupName
        == b.groupName
        && a.state
        == b.state
        && a.inboxState
        == b.inboxState
        && a.lastActivity
        == b.lastActivity



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal
            (string
                </> s "channels"
                </> string
                <?> Query.string "after"
                <?> Query.string "before"
                <?> Query.map PostStateFilter.fromQuery (Query.string "state")
                <?> Query.map InboxStateFilter.fromQuery (Query.string "inbox_state")
                <?> Query.map LastActivityFilter.fromQuery (Query.string "last_activity")
                <?> Query.map plainTextQuery (Query.string "text")
            )


plainTextQuery : Maybe String -> Bool
plainTextQuery val =
    case val of
        Just "1" ->
            True

        _ ->
            False


-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "channels", internal.groupName ] (buildQuery internal)



-- PRIVATE


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "state", PostStateFilter.toQuery internal.state )
        , ( "inbox_state", InboxStateFilter.toQuery internal.inboxState )
        , ( "last_activity", LastActivityFilter.toQuery internal.lastActivity )
        ]


buildStringParams : List ( String, Maybe String ) -> List QueryParameter
buildStringParams list =
    let
        reducer ( key, maybeValue ) queryParams =
            case maybeValue of
                Just value ->
                    Builder.string key value :: queryParams

                Nothing ->
                    queryParams
    in
    List.foldr reducer [] list
