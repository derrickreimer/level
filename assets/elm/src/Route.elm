module Route exposing (Route(..), fromUrl, href, parser, pushUrl, replaceUrl, toLogin, toSpace)

{-| Routing logic for the application.
-}

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Route.Groups
import Route.SpaceUsers
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, top)



-- ROUTING --


type Route
    = Spaces
    | NewSpace
    | Root String
    | SetupCreateGroups String
    | SetupInviteUsers String
    | Pings String
    | SpaceUsers Route.SpaceUsers.Params
    | Groups Route.Groups.Params
    | Group String String
    | NewGroup String
    | Post String String
    | UserSettings
    | SpaceSettings String


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Spaces (s "spaces")
        , Parser.map NewSpace (s "spaces" </> s "new")
        , Parser.map Root Parser.string
        , Parser.map SetupCreateGroups (Parser.string </> s "setup" </> s "groups")
        , Parser.map SetupInviteUsers (Parser.string </> s "setup" </> s "invites")
        , Parser.map Pings (Parser.string </> s "pings")
        , Parser.map SpaceUsers Route.SpaceUsers.params
        , Parser.map Groups Route.Groups.params
        , Parser.map NewGroup (Parser.string </> s "groups" </> s "new")
        , Parser.map Group (Parser.string </> s "groups" </> Parser.string)
        , Parser.map Post (Parser.string </> s "posts" </> Parser.string)
        , Parser.map UserSettings (s "user" </> s "settings")
        , Parser.map SpaceSettings (Parser.string </> s "settings")
        ]



-- INTERNAL --


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Spaces ->
                    [ "spaces" ]

                NewSpace ->
                    [ "spaces", "new" ]

                Root slug ->
                    [ slug ]

                SetupCreateGroups slug ->
                    [ slug, "setup", "groups" ]

                SetupInviteUsers slug ->
                    [ slug, "setup", "invites" ]

                Pings slug ->
                    [ slug, "pings" ]

                SpaceUsers params ->
                    Route.SpaceUsers.segments params

                Groups params ->
                    Route.Groups.segments params

                Group slug id ->
                    [ slug, "groups", id ]

                NewGroup slug ->
                    [ slug, "groups", "new" ]

                Post slug id ->
                    [ slug, "posts", id ]

                UserSettings ->
                    [ "user", "settings" ]

                SpaceSettings slug ->
                    [ slug, "settings" ]
    in
    "/" ++ String.join "/" pieces



-- PUBLIC HELPERS


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (routeToString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


toLogin : Cmd msg
toLogin =
    Nav.load "/login"


toSpace : String -> Cmd msg
toSpace slug =
    Nav.load ("/" ++ slug ++ "/")
