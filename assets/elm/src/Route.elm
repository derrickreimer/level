module Route exposing (Route(..), route, href, fromLocation, newUrl, modifyUrl, toLogin, toSpace)

{-| Routing logic for the application.
-}

import Navigation exposing (Location)
import Html exposing (Attribute)
import Html.Attributes as Attr
import UrlParser as Url exposing ((</>), Parser, oneOf, parseHash, s, string, top)
import Route.Groups


-- ROUTING --


type Route
    = Root
    | SetupCreateGroups
    | SetupInviteUsers
    | Inbox
    | Groups Route.Groups.Params
    | Group String
    | NewGroup
    | Post String
    | UserSettings
    | SpaceSettings


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Root (s "")
        , Url.map SetupCreateGroups (s "setup" </> s "groups")
        , Url.map SetupInviteUsers (s "setup" </> s "invites")
        , Url.map Inbox (s "inbox")
        , Url.map Groups Route.Groups.params
        , Url.map NewGroup (s "groups" </> s "new")
        , Url.map Group (s "groups" </> Url.string)
        , Url.map Post (s "posts" </> Url.string)
        , Url.map UserSettings (s "user" </> s "settings")
        , Url.map SpaceSettings (s "settings")
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

                Groups params ->
                    Route.Groups.toSegments params

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


newUrl : Route -> Cmd msg
newUrl =
    routeToString >> Navigation.newUrl


modifyUrl : Route -> Cmd msg
modifyUrl =
    routeToString >> Navigation.modifyUrl


fromLocation : Location -> Maybe Route
fromLocation location =
    if String.isEmpty location.hash then
        Just Root
    else
        parseHash route location


toLogin : Cmd msg
toLogin =
    Navigation.load "/login"


toSpace : String -> Cmd msg
toSpace slug =
    Navigation.load ("/" ++ slug ++ "/")
