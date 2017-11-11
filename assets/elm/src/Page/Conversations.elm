module Page.Conversations exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- UPDATE


type Msg
    = Loaded



-- VIEW


view : Html Msg
view =
    div [ id "main", class "main main--conversations" ]
        [ div [ class "page-head" ]
            [ h2 [ class "page-head__name" ] [ text "Inbox" ]
            , p [ class "page-head__description" ] [ text "All your ongoing conversations." ]
            ]
        , div [ class "convos" ]
            [ div [ class "convos__item convos__item--highlighted" ]
                [ div [ class "convos__selector" ]
                    [ label [ class "checkbox" ]
                        [ input [ type_ "checkbox" ] []
                        , span [ class "checkbox__indicator" ] []
                        ]
                    ]
                , div [ class "convos__metadata" ]
                    [ div [ class "convos__item-head" ]
                        [ span [ class "convos__subject" ] [ text "DynamoDB Brainstorming" ]
                        , span [ class "convos__dash" ] [ text "—" ]
                        , span [ class "convos__recipients" ] [ text "Developers" ]
                        ]
                    , div [ class "convos__preview" ] [ text "derrick: Have we evaluated all our options here?" ]
                    ]
                , div [ class "convos__aside" ]
                    [ span [] [ text "12:00pm" ] ]
                ]
            , div [ class "convos__item" ]
                [ div [ class "convos__selector" ]
                    [ label [ class "checkbox" ]
                        [ input [ type_ "checkbox" ] []
                        , span [ class "checkbox__indicator" ] []
                        ]
                    ]
                , div [ class "convos__metadata" ]
                    [ div [ class "convos__item-head" ]
                        [ span [ class "convos__subject" ] [ text "ID-pocalypse 2017" ]
                        , span [ class "convos__dash" ] [ text "—" ]
                        , span [ class "convos__recipients" ] [ text "Developers (+ 2 others)" ]
                        ]
                    , div [ class "convos__preview" ] [ text "derrick: Have we evaluated all our options here?" ]
                    ]
                , div [ class "convos__aside" ]
                    [ span [ class "convos__unread" ] [ text "2 unread" ]
                    , span [ class "convos__timestamp" ] [ text "12:00pm" ]
                    ]
                ]
            ]
        ]
