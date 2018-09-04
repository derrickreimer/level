module Route.Inbox exposing (Params(..), parser, toString)

import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, s, string)


type Params
    = Root String
    | After String String
    | Before String String


parser : Parser (Params -> a) a
parser =
    oneOf
        [ map Root (string </> s "inbox")
        , map After (string </> s "inbox" </> s "after" </> string)
        , map Before (string </> s "inbox" </> s "before" </> string)
        ]


toString : Params -> String
toString params =
    case params of
        Root slug ->
            absolute [ slug, "inbox" ] []

        After slug cursor ->
            absolute [ slug, "inbox", "after", cursor ] []

        Before slug cursor ->
            absolute [ slug, "inbox", "before", cursor ] []
