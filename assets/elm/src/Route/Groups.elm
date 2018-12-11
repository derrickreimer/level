module Route.Groups exposing
    ( Params, State(..)
    , init, getSpaceSlug, getAfter, getBefore, setCursors, getState, setState
    , parser
    , toString
    )

{-| Route building and parsing for the group list page.


# Types

@docs Params, State


# API

@docs init, getSpaceSlug, getAfter, getBefore, setCursors, getState, setState


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
    }


type State
    = Open
    | Closed



-- API


init : String -> Params
init spaceSlug =
    Params (Internal spaceSlug Nothing Nothing Open)


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


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }


setState : State -> Params -> Params
setState newState (Params internal) =
    Params { internal | state = newState }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "groups" <?> Query.string "after" <?> Query.string "before" <?> Query.map parseState (Query.string "state"))



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "groups" ] (buildQuery internal)



-- PRIVATE


parseState : Maybe String -> State
parseState value =
    case value of
        Just "closed" ->
            Closed

        Just "open" ->
            Open

        _ ->
            Open


castState : State -> Maybe String
castState state =
    case state of
        Open ->
            Nothing

        Closed ->
            Just "closed"


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "state", castState internal.state )
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
