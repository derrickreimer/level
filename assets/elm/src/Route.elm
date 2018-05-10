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
    | Inbox
    | SetupCreateGroups
    | SetupInviteUsers


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Root (s "")
        , Url.map Inbox (s "inbox")
        , Url.map SetupCreateGroups (s "setup" </> s "groups")
        , Url.map SetupInviteUsers (s "setup" </> s "invites")
        ]



-- INTERNAL --


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Root ->
                    []

                Inbox ->
                    [ "inbox" ]

                SetupCreateGroups ->
                    [ "setup", "groups" ]

                SetupInviteUsers ->
                    [ "setup", "invites" ]
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
    Navigation.load ("/" ++ space.slug)
