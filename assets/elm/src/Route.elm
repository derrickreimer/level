module Route exposing (Route(..), route, href, fromLocation, modifyUrl, toLogin)

{-| Routing logic for the application.
-}

import Navigation exposing (Location)
import Html exposing (Attribute)
import Html.Attributes as Attr
import UrlParser as Url exposing ((</>), Parser, oneOf, parseHash, s, string)


-- ROUTING --


type Route
    = Conversations
    | NewInvitation


route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Conversations (s "")
        , Url.map NewInvitation (s "invitations" </> s "new")
        ]



-- INTERNAL --


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Conversations ->
                    []

                NewInvitation ->
                    [ "invitations", "new" ]
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
        Just Conversations
    else
        parseHash route location


toLogin : Cmd msg
toLogin =
    Navigation.load "/login"
