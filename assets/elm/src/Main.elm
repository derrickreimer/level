module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { apiToken : String
    , currentTeam : Maybe Team
    , currentUser : Maybe User
    }


type alias Team =
    { name : String
    }


type alias User =
    { firstName : String
    , lastName : String
    }


type alias Flags =
    { apiToken : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            initialState flags
    in
        ( model, (bootstrap model) )


initialState : Flags -> Model
initialState flags =
    { apiToken = flags.apiToken
    , currentUser = Nothing
    , currentTeam = Nothing
    }


displayName : User -> String
displayName user =
    user.firstName ++ " " ++ user.lastName



-- UPDATE


type Msg
    = Bootstrapped (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Bootstrapped (Ok _) ->
            ( model, Cmd.none )

        Bootstrapped (Err _) ->
            ( model, Cmd.none )


bootstrap : Model -> Cmd Msg
bootstrap model =
    let
        body =
            """
              {
                viewer {
                  id
                  username
                  firstName
                  lastName
                  team {
                    id
                    name
                  }
                }
              }
            """

        -- TODO: replace with real decoder
        decoder =
            Decode.at [ "data", "viewer", "id" ] Decode.string

        request =
            graphqlRequest model.apiToken body decoder
    in
        Http.send Bootstrapped request


graphqlRequest : String -> String -> Decode.Decoder a -> Http.Request a
graphqlRequest token body decoder =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
        , url = "/graphql"
        , body = Http.stringBody "application/graphql" body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ div [ class "sidebar sidebar--left" ]
            [ teamSelector model.currentTeam
            , filters model
            ]
        , div [ class "sidebar sidebar--right" ]
            [ identityMenu model.currentUser
            , usersList model
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


teamSelector : Maybe Team -> Html Msg
teamSelector maybeTeam =
    case maybeTeam of
        Nothing ->
            div [ class "team-selector" ]
                [ a [ class "team-selector__toggle", href "#" ]
                    [ div [ class "team-selector__avatar team-selector__avatar--placeholder" ] []
                    , div [ class "team-selector__name team-selector__name" ]
                        [ div [ class "team-selector__loading-placeholder" ] []
                        ]
                    ]
                ]

        Just team ->
            div [ class "team-selector" ]
                [ a [ class "team-selector__toggle", href "#" ]
                    [ div [ class "team-selector__avatar" ] []
                    , div [ class "team-selector__name" ] [ text team.name ]
                    ]
                ]


identityMenu : Maybe User -> Html Msg
identityMenu maybeUser =
    case maybeUser of
        Nothing ->
            div [ class "identity-menu" ]
                [ a [ class "identity-menu__toggle", href "#" ]
                    [ div [ class "identity-menu__avatar identity-menu__avatar--placeholder" ] []
                    , div [ class "identity-menu__name" ]
                        [ div [ class "team-selector__loading-placeholder" ] []
                        ]
                    ]
                ]

        Just user ->
            div [ class "identity-menu" ]
                [ a [ class "identity-menu__toggle", href "#" ]
                    [ div [ class "identity-menu__avatar" ] []
                    , div [ class "identity-menu__name" ] [ text (displayName user) ]
                    ]
                ]


filters : Model -> Html Msg
filters model =
    div [ class "filters" ]
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


usersList : Model -> Html Msg
usersList model =
    div [ class "users-list" ]
        [ a [ class "users-list__item", href "#" ]
            [ span [ class "state-indicator state-indicator--available" ] []
            , span [ class "users-list__name" ] [ text "Tiffany Reimer" ]
            ]
        , a [ class "users-list__item", href "#" ]
            [ span [ class "state-indicator state-indicator--focus" ] []
            , span [ class "users-list__name" ] [ text "Kelli Lowe" ]
            ]
        , a [ class "users-list__item users-list__item--offline", href "#" ]
            [ span [ class "state-indicator state-indicator--offline" ] []
            , span [ class "users-list__name" ] [ text "Joe Slacker" ]
            ]
        ]
