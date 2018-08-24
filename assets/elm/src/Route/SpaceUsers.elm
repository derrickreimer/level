module Route.SpaceUsers exposing (Params(..), params, segments)

import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)


type Params
    = Root String
    | After String String
    | Before String String


params : Parser (Params -> a) a
params =
    oneOf
        [ Parser.map Root (Parser.string </> s "users")
        , Parser.map After (Parser.string </> s "users" </> s "after" </> Parser.string)
        , Parser.map Before (Parser.string </> s "users" </> s "before" </> Parser.string)
        ]


segments : Params -> List String
segments p =
    case p of
        Root slug ->
            [ slug, "users" ]

        After slug cursor ->
            [ slug, "users", "after", cursor ]

        Before slug cursor ->
            [ slug, "users", "before", cursor ]
