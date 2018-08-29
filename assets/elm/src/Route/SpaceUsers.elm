module Route.SpaceUsers exposing (Params(..), parser, toString)

import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, s, string)


type Params
    = Root String
    | After String String
    | Before String String


parser : Parser (Params -> a) a
parser =
    oneOf
        [ map Root (string </> s "users")
        , map After (string </> s "users" </> s "after" </> string)
        , map Before (string </> s "users" </> s "before" </> string)
        ]


toString : Params -> String
toString params =
    case params of
        Root slug ->
            absolute [ slug, "users" ] []

        After slug cursor ->
            absolute [ slug, "users", "after", cursor ] []

        Before slug cursor ->
            absolute [ slug, "users", "before", cursor ] []
