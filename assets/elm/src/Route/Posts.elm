module Route.Posts exposing (Params(..), getSpaceSlug, parser, toString)

import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, map, oneOf, s, string)


type Params
    = Root String
    | After String String
    | Before String String



-- API


getSpaceSlug : Params -> String
getSpaceSlug params =
    case params of
        Root slug ->
            slug

        After slug _ ->
            slug

        Before slug _ ->
            slug



-- PARSING


parser : Parser (Params -> a) a
parser =
    oneOf
        [ map Root (string </> s "posts")
        , map After (string </> s "posts" </> s "after" </> string)
        , map Before (string </> s "posts" </> s "before" </> string)
        ]


toString : Params -> String
toString params =
    case params of
        Root slug ->
            absolute [ slug, "posts" ] []

        After slug cursor ->
            absolute [ slug, "posts", "after", cursor ] []

        Before slug cursor ->
            absolute [ slug, "posts", "before", cursor ] []
