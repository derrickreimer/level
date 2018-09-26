module Route.Inbox exposing
    ( Params
    , init, getSpaceSlug, getAfter, getBefore, getState, setCursors, setState
    , parser
    , toString
    )

{-| Route building and parsing for the inbox.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getAfter, getBefore, getState, setCursors, setState


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
    , state : Maybe String
    }



-- API


init : String -> Params
init spaceSlug =
    Params (Internal spaceSlug Nothing Nothing Nothing)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getAfter : Params -> Maybe String
getAfter (Params internal) =
    internal.after


getBefore : Params -> Maybe String
getBefore (Params internal) =
    internal.before


getState : Params -> Maybe String
getState (Params internal) =
    internal.state


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }


setState : Maybe String -> Params -> Params
setState state (Params internal) =
    Params { internal | state = state }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "inbox" <?> Query.string "after" <?> Query.string "before" <?> Query.string "state")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "inbox" ] (buildQuery internal)



-- PRIVATE


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "state", internal.state )
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
