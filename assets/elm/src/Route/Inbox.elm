module Route.Inbox exposing
    ( Params, Filter(..)
    , init, getSpaceSlug, getAfter, getBefore, getFilter, setCursors, setFilter
    , parser
    , toString
    )

{-| Route building and parsing for the inbox.


# Types

@docs Params, Filter


# API

@docs init, getSpaceSlug, getAfter, getBefore, getFilter, setCursors, setFilter


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
    , filter : Filter
    }


type Filter
    = Open
    | Closed
    | Dismissed



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


getFilter : Params -> Filter
getFilter (Params internal) =
    internal.filter


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }


setFilter : Filter -> Params -> Params
setFilter filter (Params internal) =
    Params { internal | filter = filter }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "inbox" <?> Query.string "after" <?> Query.string "before" <?> Query.map parseFilter (Query.string "filter"))



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "inbox" ] (buildQuery internal)



-- PRIVATE


parseFilter : Maybe String -> Filter
parseFilter value =
    case value of
        Just "closed" ->
            Closed

        Just "dismissed" ->
            Dismissed

        Nothing ->
            Open

        _ ->
            Open


castFilter : Filter -> Maybe String
castFilter filter =
    case filter of
        Open ->
            Nothing

        Closed ->
            Just "closed"

        Dismissed ->
            Just "dismissed"


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "filter", castFilter internal.filter )
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
