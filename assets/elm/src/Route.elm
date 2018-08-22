module Route exposing (Route(..), fromUrl, href, parser, pushUrl, replaceUrl, toLogin, toSpace)

{-| Routing logic for the application.
-}

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Route.Groups
import Route.SpaceUsers
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)



-- ROUTING --


type Route
    = Root
    | SetupCreateGroups
    | SetupInviteUsers
    | Inbox
    | SpaceUsers Route.SpaceUsers.Params
    | Groups Route.Groups.Params
    | Group String
    | NewGroup
    | Post String
    | UserSettings
    | SpaceSettings


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Root (s "")
        , Parser.map SetupCreateGroups (s "setup" </> s "groups")
        , Parser.map SetupInviteUsers (s "setup" </> s "invites")
        , Parser.map Inbox (s "inbox")
        , Parser.map SpaceUsers Route.SpaceUsers.params
        , Parser.map Groups Route.Groups.params
        , Parser.map NewGroup (s "groups" </> s "new")
        , Parser.map Group (s "groups" </> Parser.string)
        , Parser.map Post (s "posts" </> Parser.string)
        , Parser.map UserSettings (s "user" </> s "settings")
        , Parser.map SpaceSettings (s "settings")
        ]



-- INTERNAL --


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Root ->
                    []

                SetupCreateGroups ->
                    [ "setup", "groups" ]

                SetupInviteUsers ->
                    [ "setup", "invites" ]

                Inbox ->
                    [ "inbox" ]

                SpaceUsers params ->
                    Route.SpaceUsers.segments params

                Groups params ->
                    Route.Groups.segments params

                Group id ->
                    [ "groups", id ]

                NewGroup ->
                    [ "groups", "new" ]

                Post id ->
                    [ "posts", id ]

                UserSettings ->
                    [ "user", "settings" ]

                SpaceSettings ->
                    [ "settings" ]
    in
    "#/" ++ String.join "/" pieces



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
    -- We are treating the the fragment like a path.
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> Parser.parse parser


toLogin : Cmd msg
toLogin =
    Nav.load "/login"


toSpace : String -> Cmd msg
toSpace slug =
    Nav.load ("/" ++ slug ++ "/")
