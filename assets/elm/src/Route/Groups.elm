module Route.Groups exposing (Params(..), parser, toString)

import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, top)


type Params
    = Root String
    | After String String
    | Before String String


parser : Parser (Params -> a) a
parser =
    oneOf
        [ Parser.map Root (Parser.string </> s "groups")
        , Parser.map After (Parser.string </> s "groups" </> s "after" </> Parser.string)
        , Parser.map Before (Parser.string </> s "groups" </> s "before" </> Parser.string)
        ]


toString : Params -> String
toString params =
    case params of
        Root slug ->
            absolute [ slug, "groups" ] []

        After slug cursor ->
            absolute [ slug, "groups", "after", cursor ] []

        Before slug cursor ->
            absolute [ slug, "groups", "before", cursor ] []
