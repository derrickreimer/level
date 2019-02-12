module Route.Posts exposing
    ( Params
    , init, getSpaceSlug, getAfter, getBefore, setCursors, getState, setState, getInboxState, setInboxState, getLastActivity, setLastActivity, clearFilters
    , parser
    , toString
    )

{-| Route building and parsing for the "Activity" page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getAfter, getBefore, setCursors, getState, setState, getInboxState, setInboxState, getLastActivity, setLastActivity, clearFilters


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
    , after : Maybe String
    , before : Maybe String
    , state : PostStateFilter
    , inboxState : InboxStateFilter
    , lastActivity : LastActivityFilter
    }



-- API


init : String -> Params
init spaceSlug =
    Params
        (Internal
            spaceSlug
            Nothing
            Nothing
            PostStateFilter.Open
            InboxStateFilter.All
            LastActivityFilter.All
        )


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


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



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        oneOf
            [ feedParser
            , inboxParser
            ]


feedParser : Parser (Internal -> a) a
feedParser =
    let
        toInternal : String -> Maybe String -> Maybe String -> PostStateFilter -> LastActivityFilter -> Internal
        toInternal spaceSlug afterCursor beforeCursor state lastActivity =
            Internal spaceSlug afterCursor beforeCursor state InboxStateFilter.All lastActivity
    in
    map toInternal
        (string
            </> s "feed"
            <?> Query.string "after"
            <?> Query.string "before"
            <?> Query.map parseFeedPostState (Query.string "state")
            <?> Query.map LastActivityFilter.fromQuery (Query.string "last_activity")
        )


inboxParser : Parser (Internal -> a) a
inboxParser =
    map Internal
        (string
            </> s "inbox"
            <?> Query.string "after"
            <?> Query.string "before"
            <?> Query.map parseInboxPostState (Query.string "state")
            <?> Query.map parseInboxState (Query.string "inbox_state")
            <?> Query.map LastActivityFilter.fromQuery (Query.string "last_activity")
        )



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    case internal.inboxState of
        InboxStateFilter.Undismissed ->
            absolute [ internal.spaceSlug, "inbox" ] (buildInboxQuery internal)

        InboxStateFilter.Dismissed ->
            absolute [ internal.spaceSlug, "inbox" ] (buildInboxQuery internal)

        _ ->
            absolute [ internal.spaceSlug, "feed" ] (buildFeedQuery internal)



-- PRIVATE


parseFeedPostState : Maybe String -> PostStateFilter
parseFeedPostState value =
    case value of
        Just "closed" ->
            PostStateFilter.Closed

        Just "all" ->
            PostStateFilter.All

        _ ->
            PostStateFilter.Open


parseInboxPostState : Maybe String -> PostStateFilter
parseInboxPostState value =
    case value of
        Just "closed" ->
            PostStateFilter.Closed

        Just "open" ->
            PostStateFilter.Open

        _ ->
            PostStateFilter.All


castFeedPostState : PostStateFilter -> Maybe String
castFeedPostState state =
    case state of
        PostStateFilter.All ->
            Just "all"

        PostStateFilter.Closed ->
            Just "closed"

        PostStateFilter.Open ->
            Nothing


castInboxPostState : PostStateFilter -> Maybe String
castInboxPostState state =
    case state of
        PostStateFilter.Open ->
            Just "open"

        PostStateFilter.Closed ->
            Just "closed"

        PostStateFilter.All ->
            Nothing


parseInboxState : Maybe String -> InboxStateFilter
parseInboxState value =
    case value of
        Just "dismissed" ->
            InboxStateFilter.Dismissed

        Just "all" ->
            InboxStateFilter.All

        _ ->
            InboxStateFilter.Undismissed


castInboxState : InboxStateFilter -> Maybe String
castInboxState state =
    case state of
        InboxStateFilter.Undismissed ->
            Nothing

        InboxStateFilter.Dismissed ->
            Just "dismissed"

        InboxStateFilter.All ->
            Just "all"


buildFeedQuery : Internal -> List QueryParameter
buildFeedQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "state", castFeedPostState internal.state )
        , ( "last_activity", LastActivityFilter.toQuery internal.lastActivity )
        ]


buildInboxQuery : Internal -> List QueryParameter
buildInboxQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "state", castInboxPostState internal.state )
        , ( "inbox_state", castInboxState internal.inboxState )
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
