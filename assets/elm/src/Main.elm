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
                [ a [ class "filters__item", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Inbox" ]
                    ]
                , a [ class "filters__item", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Everything" ]
                    ]
                , a [ class "filters__item filters__item--selected", href "#" ]
                    [ span [ class "filters__item-name" ] [ text "Drafts" ]
                    ]
                ]
            ]
        , div [ class "sidebar sidebar--right" ]
            [ div [ class "identity-menu" ]
                [ a [ class "identity-menu__toggle", href "#" ]
                    [ div [ class "identity-menu__avatar" ] []
                    , div [ class "identity-menu__name" ] [ text "Derrick Reimer" ]
                    ]
                ]
            ]
        , div [ class "main" ]
            [ div [ class "search-bar" ]
                [ input [ type_ "text", class "text-field text-field--muted search-field", placeholder "Search" ] [] ]
            , div [ class "threads" ]
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
                , div [ class "threads__item threads__item--highlighted" ]
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
            , div [ class "draft" ]
                [ div [ class "draft__row" ]
                    [ div [ class "draft__subject" ]
                        [ input [ type_ "text", class "text-field text-field--muted draft__subject-field", placeholder "Subject" ] []
                        ]
                    , div [ class "draft__recipients" ]
                        [ input [ type_ "text", class "text-field text-field--muted draft__recipients-field", placeholder "Recipients" ] []
                        ]
                    ]
                , div [ class "draft__row" ]
                    [ div [ class "draft__body" ]
                        [ textarea [ class "text-field text-field--muted textarea draft__body-field", placeholder "Message" ] [] ]
                    ]
                , div [ class "draft__row" ]
                    [ button [ class "button button--primary" ] [ text "Start New Thread" ]
                    ]
                ]
            ]
        ]
