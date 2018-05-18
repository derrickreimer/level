module Route exposing (Route(..), route, href, fromLocation, modifyUrl, toLogin, toSpace)

{-| Routing logic for the application.
-}

import Navigation exposing (Location)
import Html exposing (Attribute)
import Html.Attributes as Attr
import UrlParser as Url exposing ((</>), Parser, oneOf, parseHash, s, string)
import Data.Space exposing (Space)


-- ROUTING --


type Route
    = Root
    | SetupCreateGroups
    | SetupInviteUsers
    | Inbox
    | Group String


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Root (s "")
        , Url.map SetupCreateGroups (s "setup" </> s "groups")
        , Url.map SetupInviteUsers (s "setup" </> s "invites")
        , Url.map Inbox (s "inbox")
        , Url.map Group (s "groups" </> Url.string)
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

                Group id ->
                    [ "groups", id ]
    in
        "#/" ++ String.join "/" pieces



-- PUBLIC HELPERS


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


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


toSpace : Space -> Cmd msg
toSpace space =
    Navigation.load ("/" ++ space.slug ++ "/")
