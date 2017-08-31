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
        [ div [ class "sidebar sidebar--left" ]
            [ div [ class "team-selector" ]
                [ a [ class "team-selector__toggle", href "#" ]
                    [ div [ class "team-selector__avatar" ] []
                    , div [ class "team-selector__name" ] [ text "My Company" ]
                    ]
                ]
            , div [ class "filters" ]
                [ a [ class "filters__item filters__item--selected", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Inbox" ]
                    ]
                , a [ class "filters__item", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Everything" ]
                    ]
                ]
            , div [ class "filters" ]
                [ a [ class "filters__item", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Developers" ]
                    ]
                , a [ class "filters__item", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Marketing" ]
                    ]
                , a [ class "filters__item", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Support" ]
                    ]
                ]
            ]
        , div [ class "sidebar sidebar--right" ] []
        , div [ class "main" ] []
        ]
