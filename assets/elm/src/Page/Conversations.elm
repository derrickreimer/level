module Page.Conversations exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- UPDATE


type Msg
    = Loaded



-- VIEW


view : Html Msg
view =
    div [ class "threads" ]
        [ div [ class "threads__item threads__item--highlighted" ]
            [ div [ class "threads__selector" ]
                [ label [ class "checkbox" ]
                    [ input [ type_ "checkbox" ] []
                    , span [ class "checkbox__indicator" ] []
                    ]
                ]
            , div [ class "threads__metadata" ]
                [ div [ class "threads__item-head" ]
                    [ span [ class "threads__subject" ] [ text "DynamoDB Brainstorming" ]
                    , span [ class "threads__dash" ] [ text "—" ]
                    , span [ class "threads__recipients" ] [ text "Developers" ]
                    ]
                , div [ class "threads__preview" ] [ text "derrick: Have we evaluated all our options here?" ]
                ]
            , div [ class "threads__aside" ]
                [ span [] [ text "12:00pm" ] ]
            ]
        , div [ class "threads__item" ]
            [ div [ class "threads__selector" ]
                [ label [ class "checkbox" ]
                    [ input [ type_ "checkbox" ] []
                    , span [ class "checkbox__indicator" ] []
                    ]
                ]
            , div [ class "threads__metadata" ]
                [ div [ class "threads__item-head" ]
                    [ span [ class "threads__subject" ] [ text "ID-pocalypse 2017" ]
                    , span [ class "threads__dash" ] [ text "—" ]
                    , span [ class "threads__recipients" ] [ text "Developers (+ 2 others)" ]
                    ]
                , div [ class "threads__preview" ] [ text "derrick: Have we evaluated all our options here?" ]
                ]
            , div [ class "threads__aside" ]
                [ span [ class "threads__unread" ] [ text "2 unread" ]
                , span [ class "threads__timestamp" ] [ text "12:00pm" ]
                ]
            ]
        ]
