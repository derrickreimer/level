module Route.GroupPermissions exposing
    ( Params
    , init, getSpaceSlug, getGroupId
    , parser
    , toString
    )

{-| Route building and parsing for the group page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getGroupId


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
    , groupId : Id
    }



-- API


init : String -> Id -> Params
init spaceSlug groupId =
    Params (Internal spaceSlug groupId)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getGroupId : Params -> Id
getGroupId (Params internal) =
    internal.groupId



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "groups" </> string </> s "permissions")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "groups", internal.groupId, "permissions" ] []
