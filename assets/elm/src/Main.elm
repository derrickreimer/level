module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Data.Room exposing (RoomSubscriptionConnection, RoomSubscriptionEdge)
import Data.Space exposing (Space)
import Data.User exposing (User)
import Page.Room
import Query.Bootstrap as Bootstrap
import Navigation
import Route exposing (Route)


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChanged
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = PageNotLoaded Session
    | PageLoaded Session AppState


type alias Session =
    { apiToken : String
    }


type alias AppState =
    { currentSpace : Space
    , currentUser : User
    , roomSubscriptions : RoomSubscriptionConnection
    , page : Page
    , isTransitioning : Bool
    }


type Page
    = Blank
    | NotFound
    | Room Page.Room.Model


type alias Flags =
    { apiToken : String
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    flags
        |> buildInitialModel
        |> navigateTo (Route.fromLocation location)


buildInitialModel : Flags -> Model
buildInitialModel flags =
    PageNotLoaded (Session flags.apiToken)


displayName : User -> String
displayName user =
    user.firstName ++ " " ++ user.lastName



-- UPDATE


type Msg
    = UrlChanged Navigation.Location
    | Bootstrapped (Maybe Route) (Result Http.Error Bootstrap.Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged location ->
            ( model, Cmd.none )

        Bootstrapped maybeRoute (Ok response) ->
            case model of
                PageNotLoaded session ->
                    let
                        appState =
                            { currentUser = response.user
                            , currentSpace = response.space
                            , roomSubscriptions = response.roomSubscriptions
                            , page = Blank
                            , isTransitioning = False
                            }
                    in
                        navigateTo maybeRoute (PageLoaded session appState)

                _ ->
                    ( model, Cmd.none )

        Bootstrapped maybeRoute (Err _) ->
            ( model, Cmd.none )


bootstrap : Session -> Maybe Route -> Cmd Msg
bootstrap session maybeRoute =
    Http.send (Bootstrapped maybeRoute) (Bootstrap.request session.apiToken)


navigateTo : Maybe Route -> Model -> ( Model, Cmd Msg )
navigateTo maybeRoute model =
    case model of
        PageNotLoaded session ->
            ( model, bootstrap session maybeRoute )

        PageLoaded _ _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        PageNotLoaded _ ->
            div [ id "app" ] [ text "Loading..." ]

        PageLoaded _ appState ->
            div [ id "app" ]
                [ div [ class "sidebar sidebar--left" ]
                    [ spaceSelector appState.currentSpace
                    , sideNav appState
                    ]
                , div [ class "sidebar sidebar--right" ]
                    [ identityMenu appState.currentUser
                    , usersList appState
                    ]
                , div [ class "main" ]
                    [ div [ class "top-nav" ]
                        [ input [ type_ "text", class "text-field text-field--muted search-field", placeholder "Search" ] []
                        , button [ class "button button--primary new-conversation-button" ] [ text "New Conversation" ]
                        ]
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
                    ]
                ]


spaceSelector : Space -> Html Msg
spaceSelector space =
    div [ class "space-selector" ]
        [ a [ class "space-selector__toggle", href "#" ]
            [ div [ class "space-selector__avatar" ] []
            , div [ class "space-selector__content" ] [ text space.name ]
            ]
        ]


identityMenu : User -> Html Msg
identityMenu user =
    div [ class "identity-menu" ]
        [ a [ class "identity-menu__toggle", href "#" ]
            [ div [ class "identity-menu__avatar" ] []
            , div [ class "identity-menu__content" ]
                [ div [ class "identity-menu__name" ] [ text (displayName user) ]
                ]
            ]
        ]


sideNav : AppState -> Html Msg
sideNav appState =
    div [ class "side-nav-container" ]
        [ h3 [ class "side-nav-heading" ] [ text "Conversations" ]
        , div [ class "side-nav" ]
            [ a [ class "side-nav__item side-nav__item--selected", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Inbox" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Everything" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Drafts" ]
                ]
            ]
        , h3 [ class "side-nav-heading" ] [ text "Rooms" ]
        , roomSubscriptionsList appState
        , h3 [ class "side-nav-heading" ] [ text "Integrations" ]
        , div [ class "side-nav" ]
            [ a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "GitHub" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Honeybadger" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "New Relic" ]
                ]
            ]
        ]


usersList : AppState -> Html Msg
usersList appState =
    div [ class "side-nav-container" ]
        [ h3 [ class "side-nav-heading" ] [ text "Everyone" ]
        , div [ class "users-list" ]
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
        ]


roomSubscriptionsList : AppState -> Html Msg
roomSubscriptionsList appState =
    div [ class "side-nav" ] (List.map roomSubscriptionItem appState.roomSubscriptions.edges)


roomSubscriptionItem : RoomSubscriptionEdge -> Html Msg
roomSubscriptionItem edge =
    a [ class "side-nav__item side-nav__item--room", href "#" ]
        [ span [ class "side-nav__item-name" ] [ text edge.node.room.name ]
        ]
