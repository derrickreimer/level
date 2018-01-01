module Page.NewRoom exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- MODEL


type alias Model =
    { name : String
    }


{-| Builds the initial model for the page.
-}
initialModel : Model
initialModel =
    Model ""



-- UPDATE


type Msg
    = NoOp



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "main", class "main main--new-room" ]
        [ div [ class "cform" ]
            [ div [ class "cform__header cform__header" ]
                [ h2 [ class "cform__heading" ] [ text "Create a room" ]
                , p [ class "cform__description" ]
                    [ text "Rooms are where spontaneous discussions take place. If the topic is important, a conversation is better venue." ]
                ]
            , div [ class "cform__form" ]
                [ div [ class "form-field" ]
                    [ label [ class "form-label" ] [ text "Room Name" ]
                    , input [ type_ "text", class "text-field text-field--full text-field--large", name "name" ] []
                    ]
                , div [ class "form-controls" ]
                    [ input [ type_ "submit", value "Create room", class "button button--primary button--large" ] []
                    ]
                ]
            ]
        ]
