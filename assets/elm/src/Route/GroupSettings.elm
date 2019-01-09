module Route.GroupSettings exposing
    ( Params, Section(..)
    , init, getSpaceSlug, getGroupName, getSection, setSection
    , parser
    , toString
    )

{-| Route building and parsing for the group page.


# Types

@docs Params, Section


# API

@docs init, getSpaceSlug, getGroupName, getSection, setSection


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
    , section : Section
    }


type Section
    = General
    | Permissions



-- API


init : String -> Id -> Section -> Params
init spaceSlug groupName section =
    Params (Internal spaceSlug groupName section)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getGroupName : Params -> Id
getGroupName (Params internal) =
    internal.groupName


getSection : Params -> Section
getSection (Params internal) =
    internal.section


setSection : Section -> Params -> Params
setSection newSection (Params internal) =
    Params { internal | section = newSection }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "channels" </> string </> s "settings" </> map parseSection string)


parseSection : String -> Section
parseSection sectionSlug =
    case sectionSlug of
        "permissions" ->
            Permissions

        _ ->
            General



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "channels", internal.groupName, "settings", serializeSection internal.section ] []


serializeSection : Section -> String
serializeSection section =
    case section of
        General ->
            "general"

        Permissions ->
            "permissions"
