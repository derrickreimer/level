module Program.Spaces exposing (main)

import Avatar
import Browser exposing (Document)
import Connection exposing (Connection)
import Data.Space as Space exposing (Space)
import Data.User as User exposing (User)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Lazy exposing (Lazy(..))
import Page
import Query.SpacesInit as SpacesInit
import Route
import Session exposing (Session)
import Task
import View.Layout exposing (userLayout)


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { session : Session
    , query : String
    , user : Lazy User
    , spaces : Lazy (Connection Space)
    }


type alias Flags =
    { apiToken : String
    }



-- LIFECYCLE


init : Flags -> ( Model, Cmd Msg )
init { apiToken } =
    let
        model =
            Model (Session.init apiToken) "" NotLoaded NotLoaded
    in
    ( model
    , Cmd.batch
        [ setup model
        , Page.setTitle "My Spaces"
        ]
    )


setup : Model -> Cmd Msg
setup { session } =
    session
        |> SpacesInit.request 100
        |> Task.attempt SpacesLoaded



-- UPDATE


type Msg
    = SpacesLoaded (Result Session.Error ( Session, SpacesInit.Response ))
    | QueryChanged String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SpacesLoaded (Ok ( newSession, { user, spaces } )) ->
            ( { model | session = newSession, user = Loaded user, spaces = Loaded spaces }, Cmd.none )

        SpacesLoaded (Err Session.Expired) ->
            ( model, Route.toLogin )

        SpacesLoaded (Err _) ->
            ( model, Cmd.none )

        QueryChanged val ->
            ( { model | query = val }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    Document "Spaces"
        [ userLayout model.user <|
            div [ class "mx-auto max-w-sm" ]
                [ div [ class "flex items-center pb-6" ]
                    [ h1 [ class "flex-1 ml-4 mr-4 font-extrabold text-3xl" ] [ text "My Spaces" ]
                    , div [ class "flex-0 flex-no-shrink" ]
                        [ a [ href "/spaces/new", class "btn btn-blue btn-md no-underline" ] [ text "New space" ] ]
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
        ]


spacesView : String -> Lazy (Connection Space) -> Html Msg
spacesView query lazySpaces =
    case lazySpaces of
        NotLoaded ->
            text ""

        Loaded spaces ->
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
