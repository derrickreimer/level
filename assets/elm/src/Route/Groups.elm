module Route.Groups exposing (Params(..), params, segments)

import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, top)


type Params
    = Root String
    | After String String
    | Before String String


params : Parser (Params -> a) a
params =
    oneOf
        [ Parser.map Root (Parser.string </> s "groups")
        , Parser.map After (Parser.string </> s "groups" </> s "after" </> Parser.string)
        , Parser.map Before (Parser.string </> s "groups" </> s "before" </> Parser.string)
        ]


segments : Params -> List String
segments p =
    case p of
        Root slug ->
            [ slug, "groups" ]

        After slug cursor ->
            [ slug, "groups", "after", cursor ]

        Before slug cursor ->
            [ slug, "groups", "before", cursor ]
