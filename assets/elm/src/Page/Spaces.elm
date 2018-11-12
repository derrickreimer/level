module Page.Spaces exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Icons
import Id exposing (Id)
import Query.SpacesInit as SpacesInit
import Repo exposing (Repo)
import Route
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import User exposing (User)
import View.UserLayout



-- MODEL


type alias Model =
    { viewerId : Id
    , spaceIds : Connection Id
    , query : String
    }


type alias Data =
    { viewer : User
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map Data
        (Repo.getUser model.viewerId repo)



-- PAGE PROPERTIES


title : String
title =
    "Spaces"



-- LIFECYCLE


init : Globals -> Task Session.Error ( Globals, Model )
init globals =
    globals.session
        |> SpacesInit.request 100
        |> Task.map (buildModel globals)


buildModel : Globals -> ( Session, SpacesInit.Response ) -> ( Globals, Model )
buildModel globals ( newSession, resp ) =
    let
        model =
            Model resp.userId resp.spaceIds ""

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Scroll.toDocumentTop NoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = QueryChanged String
    | NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        QueryChanged val ->
            ( ( { model | query = val }, Cmd.none ), globals )

        NoOp ->
            ( ( model, Cmd.none ), globals )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.none



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    case resolveData repo model of
        Just data ->
            resolvedView repo model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> Model -> Data -> Html Msg
resolvedView repo model data =
    View.UserLayout.layout data.viewer <|
        div [ class "mx-auto max-w-sm" ]
            [ div [ class "flex items-center pb-6" ]
                [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text "My Spaces" ]
                , div [ class "flex-0 flex-no-shrink" ]
                    [ a [ Route.href Route.NewSpace, class "btn btn-blue btn-md no-underline" ]
                        [ text "New space" ]
                    ]
                ]
            , div [ class "pb-6" ]
                [ label [ class "flex items-center p-4 w-full rounded bg-grey-light" ]
                    [ div [ class "flex-0 flex-no-shrink pr-3" ] [ Icons.search ]
                    , input
                        [ id "search-input"
                        , type_ "text"
                        , class "flex-1 bg-transparent no-outline"
                        , placeholder "Type to search"
                        , onInput QueryChanged
                        ]
                        []
                    ]
                ]
            , spacesView repo model.query model.spaceIds
            ]


spacesView : Repo -> String -> Connection Id -> Html Msg
spacesView repo query spaceIds =
    if Connection.isEmpty spaceIds then
        blankSlateView

    else
        let
            filteredSpaces =
                Repo.getSpaces (Connection.toList spaceIds) repo
                    |> filter query
        in
        if List.isEmpty filteredSpaces then
            div [ class "ml-4 py-2 text-base" ] [ text "No spaces match your search." ]

        else
            div [ class "ml-4" ] <|
                List.map (spaceView query) filteredSpaces


blankSlateView : Html Msg
blankSlateView =
    div [ class "py-2 text-center text-lg" ] [ text "You aren't a member of any spaces yet!" ]


spaceView : String -> Space -> Html Msg
spaceView query space =
    a [ href ("/" ++ Space.slug space ++ "/"), class "flex items-center pr-4 pb-1 no-underline text-blue" ]
        [ div [ class "mr-3" ] [ Space.avatar Avatar.Small space ]
        , h2 [ class "font-normal text-lg" ] [ text <| Space.name space ]
        ]


filter : String -> List Space -> List Space
filter query spaces =
    let
        doesMatch space =
            space
                |> Space.name
                |> String.toLower
                |> String.contains (String.toLower query)
    in
    List.filter doesMatch spaces
