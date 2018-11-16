module Route.Settings exposing
    ( Params, Section(..)
    , init, getSpaceSlug, getSection, setSection
    , parser
    , toString
    )

{-| Route building and parsing for the space user directory.


# Types

@docs Params, Section


# API

@docs init, getSpaceSlug, getSection, setSection


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


type Section
    = Preferences
    | Space


type alias Internal =
    { spaceSlug : String
    , section : Section
    }



-- API


init : String -> Section -> Params
init spaceSlug section =
    Params (Internal spaceSlug section)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


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
        map Internal (string </> s "settings" </> map parseSection string)


parseSection : String -> Section
parseSection sectionSlug =
    case sectionSlug of
        "space" ->
            Space

        _ ->
            Preferences



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "settings", serializeSection internal.section ] []


serializeSection : Section -> String
serializeSection section =
    case section of
        Preferences ->
            "preferences"

        Space ->
            "space"
