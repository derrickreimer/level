module Route.SpaceUsers exposing (Params(..), params, segments)

import Vendor.UrlParser as Url exposing ((</>), Parser, oneOf, parseHash, s, string, top)


type Params
    = Root
    | After String
    | Before String


params : Parser (Params -> a) a
params =
    oneOf
        [ Url.map Root (s "users")
        , Url.map After (s "users" </> s "after" </> Url.string)
        , Url.map Before (s "users" </> s "before" </> Url.string)
        ]


segments : Params -> List String
segments params =
    case params of
        Root ->
            [ "users" ]

        After cursor ->
            [ "users", "after", cursor ]

        Before cursor ->
            [ "users", "before", cursor ]
