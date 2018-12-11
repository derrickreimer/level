module Route.SpaceUser exposing
    ( Params
    , init, getSpaceSlug, getSpaceUserId
    , parser
    , toString
    )

{-| Route building and parsing for the space user page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getSpaceUserId


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
    , spaceUserId : Id
    }



-- API


init : String -> Id -> Params
init spaceSlug spaceUserId =
    Params (Internal spaceSlug spaceUserId)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getSpaceUserId : Params -> Id
getSpaceUserId (Params internal) =
    internal.spaceUserId



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "users" </> string)



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "users", internal.spaceUserId ] []
