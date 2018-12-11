module Route exposing (Route(..), fromUrl, href, parser, pushUrl, replaceUrl, toLogin, toSpace)

{-| Routing logic for the application.
-}

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Route.Group
import Route.GroupSettings
import Route.Groups
import Route.Help
import Route.Inbox
import Route.Posts
import Route.Search
import Route.Settings
import Route.SpaceUser
import Route.SpaceUsers
import Route.WelcomeTutorial
import Url exposing (Url)
import Url.Builder as Builder exposing (absolute)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, top)



-- ROUTING --


type Route
    = Spaces
    | NewSpace
    | Root String
    | Posts Route.Posts.Params
    | Inbox Route.Inbox.Params
    | SpaceUsers Route.SpaceUsers.Params
    | SpaceUser Route.SpaceUser.Params
    | InviteUsers String
    | Groups Route.Groups.Params
    | Group Route.Group.Params
    | NewGroup String
    | GroupSettings Route.GroupSettings.Params
    | Post String String
    | UserSettings
    | Settings Route.Settings.Params
    | Search Route.Search.Params
    | WelcomeTutorial Route.WelcomeTutorial.Params
    | Help Route.Help.Params


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Spaces (s "spaces")
        , Parser.map NewSpace (s "spaces" </> s "new")
        , Parser.map Root Parser.string
        , Parser.map Posts Route.Posts.parser
        , Parser.map Inbox Route.Inbox.parser
        , Parser.map SpaceUsers Route.SpaceUsers.parser
        , Parser.map SpaceUser Route.SpaceUser.parser
        , Parser.map InviteUsers (Parser.string </> s "invites")
        , Parser.map Groups Route.Groups.parser
        , Parser.map NewGroup (Parser.string </> s "groups" </> s "new")
        , Parser.map GroupSettings Route.GroupSettings.parser
        , Parser.map Group Route.Group.parser
        , Parser.map Post (Parser.string </> s "posts" </> Parser.string)
        , Parser.map UserSettings (s "user" </> s "settings")
        , Parser.map Settings Route.Settings.parser
        , Parser.map Search Route.Search.parser
        , Parser.map WelcomeTutorial Route.WelcomeTutorial.parser
        , Parser.map Help Route.Help.parser
        ]



-- PUBLIC HELPERS


href : Route -> Attribute msg
href route =
    Attr.href (toString route)


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (toString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (toString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


toLogin : Cmd msg
toLogin =
    Nav.load "/login"


toSpace : String -> Cmd msg
toSpace slug =
    Nav.load ("/" ++ slug ++ "/")



-- INTERNAL --


toString : Route -> String
toString page =
    case page of
        Spaces ->
            absolute [ "spaces" ] []

        NewSpace ->
            absolute [ "spaces", "new" ] []

        Root slug ->
            absolute [ slug ] []

        Posts params ->
            Route.Posts.toString params

        Inbox params ->
            Route.Inbox.toString params

        SpaceUser params ->
            Route.SpaceUser.toString params

        SpaceUsers params ->
            Route.SpaceUsers.toString params

        InviteUsers slug ->
            absolute [ slug, "invites" ] []

        Groups params ->
            Route.Groups.toString params

        Group params ->
            Route.Group.toString params

        NewGroup slug ->
            absolute [ slug, "groups", "new" ] []

        GroupSettings params ->
            Route.GroupSettings.toString params

        Post slug id ->
            absolute [ slug, "posts", id ] []

        UserSettings ->
            absolute [ "user", "settings" ] []

        Settings params ->
            Route.Settings.toString params

        Search params ->
            Route.Search.toString params

        WelcomeTutorial params ->
            Route.WelcomeTutorial.toString params

        Help params ->
            Route.Help.toString params
