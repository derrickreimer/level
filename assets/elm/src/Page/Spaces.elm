module Page.Spaces exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Icons
import Query.SpacesInit as SpacesInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import Space exposing (Space)
import Task exposing (Task)
import User exposing (User)
import View.Layout exposing (userLayout)



-- MODEL


type alias Model =
    { viewer : User
    , spaces : Connection Space
    , query : String
    }



-- PAGE PROPERTIES


title : String
title =
    "Spaces"



-- LIFECYCLE


init : Session -> Task Session.Error ( Session, Model )
init session =
    session
        |> SpacesInit.request 100
        |> Task.andThen buildModel


buildModel : ( Session, SpacesInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { user, spaces } ) =
    let
        model =
            Model user spaces ""
    in
    Task.succeed ( session, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = QueryChanged String


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        QueryChanged val ->
            ( ( { model | query = val }, Cmd.none ), globals )



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
    userLayout model.viewer <|
        div [ class "mx-auto max-w-sm" ]
            [ div [ class "flex items-center pb-6" ]
                [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text "My Spaces" ]
                , div [ class "flex-0 flex-no-shrink" ]
                    [ a [ Route.href Route.NewSpace, class "btn btn-blue btn-md no-underline" ] [ text "New space" ] ]
                ]
            , div [ class "pb-6" ]
                [ label [ class "flex p-4 w-full rounded bg-grey-light" ]
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
            , spacesView model.query model.spaces
            ]


spacesView : String -> Connection Space -> Html Msg
spacesView query spaces =
    if Connection.isEmpty spaces then
        blankSlateView

    else
        let
            filteredSpaces =
                spaces
                    |> Connection.toList
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


spaceView : String -> Space.Record -> Html Msg
spaceView query spaceData =
    a [ href ("/" ++ spaceData.slug ++ "/"), class "flex items-center pr-4 pb-1 no-underline text-blue" ]
        [ div [ class "mr-3" ] [ Avatar.thingAvatar Avatar.Small spaceData ]
        , h2 [ class "font-normal text-lg" ] [ text spaceData.name ]
        ]


filter : String -> List Space -> List Space.Record
filter query spaces =
    let
        matches value =
            value
                |> String.toLower
                |> String.contains (String.toLower query)
    in
    spaces
        |> List.map (\space -> Space.getCachedData space)
        |> List.filter (\data -> matches data.name)
