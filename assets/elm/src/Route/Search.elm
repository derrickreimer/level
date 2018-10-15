module Route.Search exposing
    ( Params
    , init, getSpaceSlug, getQuery, getAfter, getBefore, setCursors
    , parser
    , toString
    )

{-| Route building and parsing for the search page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getQuery, getAfter, getBefore, setCursors


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
    , query : Maybe String
    , after : Maybe String
    , before : Maybe String
    }



-- API


init : String -> String -> Params
init spaceSlug query =
    Params (Internal spaceSlug (Just query) Nothing Nothing)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getQuery : Params -> Maybe String
getQuery (Params internal) =
    internal.query


getAfter : Params -> Maybe String
getAfter (Params internal) =
    internal.after


getBefore : Params -> Maybe String
getBefore (Params internal) =
    internal.before


setQuery : String -> Params -> Params
setQuery newQuery (Params internal) =
    Params { internal | query = Just newQuery }


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "search" <?> Query.string "q" <?> Query.string "after" <?> Query.string "before")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "search" ] (buildQuery internal)



-- PRIVATE


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    buildStringParams
        [ ( "q", internal.query )
        , ( "after", internal.after )
        , ( "before", internal.before )
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
