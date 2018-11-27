module Route.Help exposing
    ( Params
    , init, getSpaceSlug
    , parser
    , toString
    )

{-| Route building and parsing for the help page.


# Types

@docs Params


# API

@docs init, getSpaceSlug


# Parsing

@docs parser


# Serialization

@docs toString

-}

import Url.Builder as Builder exposing (QueryParameter, absolute)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, int, map, oneOf, s, string)
import Url.Parser.Query as Query


type Params
    = Params Internal


type alias Internal =
    { spaceSlug : String
    }



-- API


init : String -> Params
init spaceSlug =
    Params (Internal spaceSlug)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "help")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "help" ] []
