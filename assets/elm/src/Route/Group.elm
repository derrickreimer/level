module Route.Group exposing (Params(..), parser, toString)

import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, s, string)


type Params
    = Root String String
    | After String String String
    | Before String String String


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
