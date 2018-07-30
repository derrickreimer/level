module Route.Groups exposing (Params(..), params, toSegments)

import UrlParser as Url exposing ((</>), Parser, oneOf, parseHash, s, string, top)


type Params
    = Root
    | After String
    | Before String


params : Parser (Params -> a) a
params =
    oneOf
        [ Url.map Root (s "groups")
        , Url.map After (s "groups" </> s "after" </> Url.string)
        , Url.map Before (s "groups" </> s "before" </> Url.string)
        ]


toSegments : Params -> List String
toSegments params =
    case params of
        Root ->
            [ "groups" ]

        After cursor ->
            [ "groups", "after", cursor ]

        Before cursor ->
            [ "groups", "before", cursor ]
