module Route.Pings exposing (Params(..), parser, toString)

import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, s, string)


type Params
    = Root String
    | After String String
    | Before String String


parser : Parser (Params -> a) a
parser =
    oneOf
        [ map Root (string </> s "pings")
        , map After (string </> s "pings" </> s "after" </> string)
        , map Before (string </> s "pings" </> s "before" </> string)
        ]


toString : Params -> String
toString params =
    case params of
        Root slug ->
            absolute [ slug, "pings" ] []

        After slug cursor ->
            absolute [ slug, "pings", "after", cursor ] []

        Before slug cursor ->
            absolute [ slug, "pings", "before", cursor ] []
