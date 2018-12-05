module Route.Inbox exposing
    ( Params, State(..), LastActivity(..)
    , init, getSpaceSlug, getAfter, getBefore, getState, getLastActivity, setCursors, setState, setLastActivity
    , parser
    , toString
    )

{-| Route building and parsing for the inbox.


# Types

@docs Params, State, LastActivity


# API

@docs init, getSpaceSlug, getAfter, getBefore, getState, getLastActivity, setCursors, setState, setLastActivity


# Parsing

@docs parser


# Serialization

@docs toString

-}

import Url.Builder as Builder exposing (QueryParameter, absolute)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string)
import Url.Parser.Query as Query


type Params
    = Params Internal


type alias Internal =
    { spaceSlug : String
    , after : Maybe String
    , before : Maybe String
    , state : State
    , lastActivity : LastActivity
    }


type State
    = Undismissed
    | Dismissed


type LastActivity
    = All
    | Today



-- API


init : String -> Params
init spaceSlug =
    Params (Internal spaceSlug Nothing Nothing Undismissed All)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getAfter : Params -> Maybe String
getAfter (Params internal) =
    internal.after


getBefore : Params -> Maybe String
getBefore (Params internal) =
    internal.before


getState : Params -> State
getState (Params internal) =
    internal.state


getLastActivity : Params -> LastActivity
getLastActivity (Params internal) =
    internal.lastActivity


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }


setState : State -> Params -> Params
setState state (Params internal) =
    Params { internal | state = state }


setLastActivity : LastActivity -> Params -> Params
setLastActivity lastActivity (Params internal) =
    Params { internal | lastActivity = lastActivity }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal
            (string
                </> s "inbox"
                <?> Query.string "after"
                <?> Query.string "before"
                <?> Query.map parseState (Query.string "state")
                <?> Query.map parseLastActivity (Query.string "last_activity")
            )



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "inbox" ] (buildQuery internal)



-- PRIVATE


parseState : Maybe String -> State
parseState value =
    case value of
        Just "dismissed" ->
            Dismissed

        Nothing ->
            Undismissed

        _ ->
            Undismissed


parseLastActivity : Maybe String -> LastActivity
parseLastActivity value =
    case value of
        Just "today" ->
            Today

        Nothing ->
            All

        _ ->
            All


castState : State -> Maybe String
castState state =
    case state of
        Undismissed ->
            Nothing

        Dismissed ->
            Just "dismissed"


castLastActivity : LastActivity -> Maybe String
castLastActivity lastActivity =
    case lastActivity of
        All ->
            Nothing

        Today ->
            Just "today"


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "state", castState internal.state )
        , ( "last_activity", castLastActivity internal.lastActivity )
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
