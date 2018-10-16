module Route.Search exposing
    ( Params
    , init, getSpaceSlug, getQuery, getPage, setPage, incrementPage, decrementPage
    , parser
    , toString
    )

{-| Route building and parsing for the search page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getQuery, getPage, setPage, incrementPage, decrementPage


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
    , page : Maybe Int
    }



-- API


init : String -> String -> Params
init spaceSlug query =
    Params (Internal spaceSlug (Just query) Nothing)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getQuery : Params -> Maybe String
getQuery (Params internal) =
    internal.query


getPage : Params -> Maybe Int
getPage (Params internal) =
    internal.page


setQuery : String -> Params -> Params
setQuery newQuery (Params internal) =
    Params { internal | query = Just newQuery }


setPage : Maybe Int -> Params -> Params
setPage maybePage (Params internal) =
    Params { internal | page = maybePage }


incrementPage : Params -> Params
incrementPage (Params internal) =
    case internal.page of
        Just val ->
            Params { internal | page = Just (val + 1) }

        Nothing ->
            Params { internal | page = Just 2 }


decrementPage : Params -> Params
decrementPage (Params internal) =
    case internal.page of
        Just val ->
            if val > 2 then
                Params { internal | page = Just (val - 1) }

            else
                Params { internal | page = Nothing }

        Nothing ->
            Params { internal | page = Nothing }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "search" <?> Query.string "q" <?> Query.int "page")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "search" ] (buildQuery internal)



-- PRIVATE


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    let
        qs1 =
            case internal.query of
                Just value ->
                    [ Builder.string "q" value ]

                Nothing ->
                    []

        qs2 =
            case internal.page of
                Just value ->
                    Builder.int "page" value :: qs1

                Nothing ->
                    qs1
    in
    qs2
