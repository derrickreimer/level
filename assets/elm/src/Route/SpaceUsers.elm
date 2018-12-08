module Route.SpaceUsers exposing
    ( Params
    , init, getSpaceSlug, getAfter, getBefore, getQuery, setCursors, setQuery
    , parser
    , toString
    )

{-| Route building and parsing for the space user directory.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getAfter, getBefore, getQuery, setCursors, setQuery


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
    , query : Maybe String
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


getQuery : Params -> String
getQuery (Params internal) =
    internal.query
        |> Maybe.withDefault ""


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }


setQuery : String -> Params -> Params
setQuery query (Params internal) =
    Params { internal | query = Just query }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "users" <?> Query.string "after" <?> Query.string "before" <?> Query.string "q")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "users" ] (buildQuery internal)


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    let
        query =
            case internal.query of
                Just "" ->
                    Nothing

                val ->
                    val
    in
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        , ( "q", query )
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
