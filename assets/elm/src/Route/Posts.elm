module Route.Posts exposing
    ( Params
    , init, getSpaceSlug, getAfter, getBefore, setCursors
    , parser
    , toString
    )

{-| Route building and parsing for the "Activity" page.


# Types

@docs Params


# API

@docs init, getSpaceSlug, getAfter, getBefore, setCursors


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
    , after : Maybe String
    , before : Maybe String
    }



-- API


init : String -> Params
init spaceSlug =
    Params (Internal spaceSlug Nothing Nothing)


getSpaceSlug : Params -> String
getSpaceSlug (Params internal) =
    internal.spaceSlug


getAfter : Params -> Maybe String
getAfter (Params internal) =
    internal.after


getBefore : Params -> Maybe String
getBefore (Params internal) =
    internal.before


setCursors : Maybe String -> Maybe String -> Params -> Params
setCursors before after (Params internal) =
    Params { internal | before = before, after = after }



-- PARSING


parser : Parser (Params -> a) a
parser =
    map Params <|
        map Internal (string </> s "posts" <?> Query.string "after" <?> Query.string "before")



-- SERIALIZATION


toString : Params -> String
toString (Params internal) =
    absolute [ internal.spaceSlug, "posts" ] (buildQuery internal)



-- PRIVATE


buildQuery : Internal -> List QueryParameter
buildQuery internal =
    buildStringParams
        [ ( "after", internal.after )
        , ( "before", internal.before )
        ]


buildStringParams : List ( String, Maybe String ) -> List QueryParameter
buildStringParams list =
    let
        reducer ( key, maybeValue ) queryParams =
            case maybeValue of
                Just value ->
                    Builder.string key value :: queryParams

                Nothing ->
                    queryParams
    in
    List.foldr reducer [] list
