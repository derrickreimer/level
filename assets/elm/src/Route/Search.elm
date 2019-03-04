module Route.Search exposing
    ( Params
    , init, getSpaceSlug, getQuery
    , parser
    , toString
    )

{-| Route building and parsing for the search page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getQuery


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
    }



-- API


init : String -> Maybe String -> Params
init spaceSlug maybeQuery =
    Params (Internal spaceSlug maybeQuery)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getQuery : Params -> Maybe String
getQuery (Params internal) =
    internal.query



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "search" <?> Query.string "q")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "search" ] (buildQuery internal)



-- PRIVATE


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    case internal.query of
        Just value ->
            [ Builder.string "q" value ]

        Nothing ->
            []
