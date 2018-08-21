module Route.SpaceUsers exposing (Params(..), params, segments)

import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)


type Params
    = Root
    | After String
    | Before String


params : Parser (Params -> a) a
params =
    oneOf
        [ Parser.map Root (s "users")
        , Parser.map After (s "users" </> s "after" </> Parser.string)
        , Parser.map Before (s "users" </> s "before" </> Parser.string)
        ]


segments : Params -> List String
segments p =
    case p of
        Root ->
            [ "users" ]

        After cursor ->
            [ "users", "after", cursor ]

        Before cursor ->
            [ "users", "before", cursor ]
