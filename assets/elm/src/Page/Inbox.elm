module Page.Inbox
    exposing
        ( Model
        , Msg(..)
        , title
        , init
        , setup
        , teardown
        , update
        , subscriptions
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Avatar exposing (personAvatar)
import Connection exposing (Connection)
import Data.Mention as Mention exposing (Mention)
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Date exposing (Date)
import Icons
import Query.InboxInit as InboxInit
import Repo exposing (Repo)
import Route
import Route.SpaceUsers
import Session exposing (Session)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Time, every, second)
import View.Helpers exposing (displayName, injectHtml, smartFormatDate)


-- MODEL


type alias Model =
    { space : Space
    , mentions : Connection Mention
    , now : Date
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
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.andThen (buildModel space)


buildModel : Space -> ( ( Session, InboxInit.Response ), Date ) -> Task Session.Error ( Session, Model )
buildModel space ( ( session, { mentions } ), now ) =
    Task.succeed ( session, Model space mentions now )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = Tick Time


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        Tick time ->
            { model | now = Date.fromTime time }
                |> noCmd session


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every second Tick



-- VIEW


view : Repo -> List SpaceUser -> Model -> Html Msg
view repo featuredUsers model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ div [ class "group-header sticky pin-t border-b py-4 bg-white z-50" ]
                [ div [ class "flex items-center" ]
                    [ h2 [ class "font-extrabold text-2xl" ] [ text "Inbox" ]
                    ]
                ]
            , mentionsView repo model.now model.mentions
            , sidebarView repo featuredUsers
            ]
        ]


mentionsView : Repo -> Date -> Connection Mention -> Html Msg
mentionsView repo now mentions =
    div []
        [ h3 [ class "font-extrabold" ] [ text "Mentions" ]
        , div [] <|
            Connection.map (mentionView repo now) mentions
        ]


mentionView : Repo -> Date -> Mention -> Html Msg
mentionView repo now mention =
    let
        mentionData =
            Mention.getCachedData mention

        postData =
            Repo.getPost repo mentionData.post

        authorData =
            Repo.getSpaceUser repo postData.author
    in
        div [ classList [ ( "pb-4", True ) ] ]
            [ div [ class "flex pt-4 px-4" ]
                [ div [ class "flex-no-shrink mr-4" ] [ personAvatar Avatar.Medium authorData ]
                , div [ class "flex-grow leading-semi-loose" ]
                    [ div []
                        [ a
                            [ Route.href <| Route.Post postData.id
                            , class "flex items-baseline no-underline text-dusty-blue-darkest"
                            , rel "tooltip"
                            , Html.Attributes.title "Expand post"
                            ]
                            [ span [ class "font-bold" ] [ text <| displayName authorData ]
                            , span [ class "mx-3 text-sm text-dusty-blue" ] [ text <| smartFormatDate now postData.postedAt ]
                            ]
                        , div [ class "markdown mb-2" ] [ injectHtml [] postData.bodyHtml ]
                        ]
                    ]
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
