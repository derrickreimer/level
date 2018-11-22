module Route.Tutorial exposing
    ( Params
    , init, getSpaceSlug, getStep, setStep
    , parser
    , toString
    )

{-| Route building and parsing for the space user directory.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getStep, setStep


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
    , step : Int
    }



-- API


init : String -> Int -> Params
init spaceSlug step =
    Params (Internal spaceSlug step)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getStep : Params -> Int
getStep (Params internal) =
    internal.step


setStep : Int -> Params -> Params
setStep newStep (Params internal) =
    Params { internal | step = newStep }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "tutorial" </> int)



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "tutorial", String.fromInt internal.step ] []
