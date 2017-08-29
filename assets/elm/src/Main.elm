module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


main : Program Never Model Msg
main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = update
        }



-- MODEL


type alias Model =
    { team_name : String
    }


model : Model
model =
    { team_name = "" }



-- UPDATE


type Msg
    = Bootstrapped


update : Msg -> Model -> Model
update msg model =
    case msg of
        Bootstrapped ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ div [ class "sidebar sidebar--left" ] []
        , div [ class "sidebar sidebar--right" ] []
        , div [ class "main" ] []
        ]
