module Route.SpaceUsers exposing (Params(..), parser, toString)

import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)


type Params
    = Root String
    | After String String
    | Before String String


parser : Parser (Params -> a) a
parser =
    oneOf
        [ Parser.map Root (Parser.string </> s "users")
        , Parser.map After (Parser.string </> s "users" </> s "after" </> Parser.string)
        , Parser.map Before (Parser.string </> s "users" </> s "before" </> Parser.string)
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
