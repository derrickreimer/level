module Route.Group exposing (Params(..), after, before, parser, toString)

import Id exposing (Id)
import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, s, string)


type Params
    = Root String Id
    | After String Id String
    | Before String Id String


parser : Parser (Params -> a) a
parser =
    oneOf
        [ map Root (string </> s "groups" </> string)
        , map After (string </> s "groups" </> string </> s "after" </> string)
        , map Before (string </> s "groups" </> string </> s "before" </> string)
        ]


toString : Params -> String
toString params =
    case params of
        Root slug id ->
            absolute [ slug, "groups", id ] []

        After slug id cursor ->
            absolute [ slug, "groups", id, "after", cursor ] []

        Before slug id cursor ->
            absolute [ slug, "groups", id, "before", cursor ] []



-- MUTATORS


after : Params -> String -> Params
after params cursor =
    let
        ( slug, id ) =
            staticParts params
    in
    After slug id cursor


before : Params -> String -> Params
before params cursor =
    let
        ( slug, id ) =
            staticParts params
    in
    Before slug id cursor



-- INTERNAL


staticParts : Params -> ( String, Id )
staticParts params =
    case params of
        Root slug id ->
            ( slug, id )

        After slug id _ ->
            ( slug, id )

        Before slug id _ ->
            ( slug, id )
