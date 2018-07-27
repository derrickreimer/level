module Page.NewGroup
    exposing
        ( Model
        , Msg(..)
        , init
        , setup
        , teardown
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (Task)
import Data.Space as Space exposing (Space)
import Session exposing (Session)


-- MODEL


type alias Model =
    { space : Space
    }



-- LIFECYCLE


init : Space -> Task Never Model
init space =
    Task.succeed (buildModel space)


buildModel : Space -> Model
buildModel space =
    Model space


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    ( ( model, Cmd.none ), session )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-sm leading-normal py-8" ]
            [ div [ class "flex items-center pb-5" ]
                [ h1 [ class "flex-1 font-extrabold text-3xl" ] [ text "Create a group" ]
                ]
            ]
        ]
