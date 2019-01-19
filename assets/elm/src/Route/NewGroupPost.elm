module Route.NewGroupPost exposing
    ( Params
    , init, getSpaceSlug, getGroupName, hasSamePath
    , parser
    , toString
    )

{-| Route building and parsing for the new group post page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getGroupName, hasSamePath


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
    , groupName : Id
    }



-- API


init : String -> Id -> Params
init spaceSlug groupName =
    Params (Internal spaceSlug groupName)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getGroupName : Params -> Id
getGroupName (Params internal) =
    internal.groupName


hasSamePath : Params -> Params -> Bool
hasSamePath p1 p2 =
    getSpaceSlug p1 == getSpaceSlug p2 && getGroupName p1 == getGroupName p2



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "channels" </> string </> s "posts" </> s "new")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "channels", internal.groupName, "posts", "new" ] []
