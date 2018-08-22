module Route.Groups exposing (Params(..), params, segments)

import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, top)


type Params
    = Root
    | After String
    | Before String


params : Parser (Params -> a) a
params =
    oneOf
        [ Parser.map Root (s "groups")
        , Parser.map After (s "groups" </> s "after" </> Parser.string)
        , Parser.map Before (s "groups" </> s "before" </> Parser.string)
        ]


segments : Params -> List String
segments p =
    case p of
        Root ->
            [ "groups" ]

        After cursor ->
            [ "groups", "after", cursor ]

        Before cursor ->
            [ "groups", "before", cursor ]
