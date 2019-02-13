module Route.SpaceUser exposing
    ( Params
    , init, getSpaceSlug, getHandle
    , parser
    , toString
    )

{-| Route building and parsing for the space user page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getHandle


# Parsing

@docs parser


# Serialization

@docs toString

-}

import Id exposing (Id)
import Url.Builder as Builder exposing (QueryParameter, absolute)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string)
import Url.Parser.Query as Query


type Params
    = Params Internal


type alias Internal =
    { spaceSlug : String
    , handle : String
    }



-- API


init : String -> Id -> Params
init spaceSlug handle =
    Params (Internal spaceSlug handle)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getHandle : Params -> Id
getHandle (Params internal) =
    internal.handle



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "users" </> string)



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "users", internal.handle ] []
