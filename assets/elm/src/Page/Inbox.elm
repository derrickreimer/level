module Page.Inbox
    exposing
        ( Model
        , Msg(..)
        , title
        , init
        , setup
        , teardown
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Avatar exposing (personAvatar)
import Connection exposing (Connection)
import Data.Mention as Mention exposing (Mention)
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Icons
import Query.InboxInit as InboxInit
import Repo exposing (Repo)
import Route
import Route.SpaceUsers
import Session exposing (Session)
import Task exposing (Task)
import View.Helpers exposing (displayName)


-- MODEL


type alias Model =
    { space : Space
    , mentions : Connection Mention
    }



-- PAGE PROPERTIES


title : String
title =
    "Inbox"



-- LIFECYCLE


init : Space -> Session -> Task Session.Error ( Session, Model )
init space session =
    session
        |> InboxInit.request (Space.getId space)
        |> Task.andThen (buildModel space)


buildModel : Space -> ( Session, InboxInit.Response ) -> Task Session.Error ( Session, Model )
buildModel space ( session, { mentions } ) =
    Task.succeed ( session, Model space mentions )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = Loaded



-- VIEW


view : Repo -> List SpaceUser -> Html Msg
view repo featuredUsers =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ div [ class "group-header sticky pin-t border-b py-4 bg-white z-50" ]
                [ div [ class "flex items-center" ]
                    [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text "Inbox" ]
                    ]
                ]
            , sidebarView repo featuredUsers
            ]
        ]


sidebarView : Repo -> List SpaceUser -> Html Msg
sidebarView repo featuredUsers =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ]
            [ a
                [ Route.href (Route.SpaceUsers Route.SpaceUsers.Root)
                , class "flex items-center text-dusty-blue-darkest no-underline"
                ]
                [ span [ class "mr-2" ] [ text "Directory" ]
                , Icons.arrowUpRight
                ]
            ]
        , div [ class "pb-4" ] <| List.map (userItemView repo) featuredUsers
        , a
            [ Route.href Route.SpaceSettings
            , class "text-sm text-blue no-underline"
            ]
            [ text "Manage this space" ]
        ]


userItemView : Repo -> SpaceUser -> Html Msg
userItemView repo user =
    let
        userData =
            user
                |> Repo.getSpaceUser repo
    in
        div [ class "flex items-center pr-4 mb-px" ]
            [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny userData ]
            , div [ class "flex-grow text-sm truncate" ] [ text <| displayName userData ]
            ]
