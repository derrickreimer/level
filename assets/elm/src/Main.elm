module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Data.Room exposing (RoomSubscriptionConnection, RoomSubscriptionEdge)
import Data.Space exposing (Space)
import Data.User exposing (User)
import Data.Session exposing (Session)
import Page.Room
import Page.Conversations
import Query.AppState
import Query.Room
import Navigation
import Route exposing (Route)
import Task


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChanged
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Lazy a
    = NotLoaded
    | Loaded a


type alias Model =
    { session : Session
    , appState : Lazy AppState
    , page : Page
    , isTransitioning : Bool
    }


type alias AppState =
    { space : Space
    , user : User
    , roomSubscriptions : RoomSubscriptionConnection
    }


type Page
    = Blank
    | NotFound
    | Conversations -- TODO: add a model to this type
    | Room Page.Room.Model


type alias Flags =
    { apiToken : String
    }


{-| Initialize the model and kick off page navigation.

1.  Build the initial model, which begins life as a `NotBootstrapped` type.
2.  Parse the route from the location and navigate to the page.
3.  Bootstrap the application state first, then perform the queries
    required for the specific route.

-}
init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    flags
        |> buildInitialModel
        |> navigateTo (Route.fromLocation location)


{-| Build the initial model, before running the page "bootstrap" query.
-}
buildInitialModel : Flags -> Model
buildInitialModel flags =
    Model (Session flags.apiToken) NotLoaded Blank True



-- UPDATE


type Msg
    = UrlChanged Navigation.Location
    | AppStateLoaded (Maybe Route) (Result Http.Error Query.AppState.Response)
    | RoomLoaded String (Result Http.Error Query.Room.Response)
    | ConversationsMsg Page.Conversations.Msg
    | RoomMsg Page.Room.Msg


getSession : Model -> Session
getSession model =
    model.session


getPage : Model -> Page
getPage model =
    model.page


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        page =
            getPage model
    in
        case ( msg, page ) of
            ( UrlChanged location, _ ) ->
                navigateTo (Route.fromLocation location) model

            ( AppStateLoaded maybeRoute (Ok response), _ ) ->
                navigateTo maybeRoute { model | appState = Loaded response }

            ( AppStateLoaded maybeRoute (Err _), _ ) ->
                ( model, Cmd.none )

            ( RoomLoaded slug (Ok response), _ ) ->
                case response of
                    Query.Room.Found data ->
                        ( { model
                            | page = Room (Page.Room.buildModel data)
                            , isTransitioning = False
                          }
                        , Cmd.none
                        )

                    Query.Room.NotFound ->
                        ( { model
                            | page = NotFound
                            , isTransitioning = False
                          }
                        , Cmd.none
                        )

            ( RoomLoaded slug (Err _), _ ) ->
                ( model, Cmd.none )

            ( ConversationsMsg _, _ ) ->
                -- TODO: implement this
                ( model, Cmd.none )

            ( RoomMsg msg, Room pageModel ) ->
                -- TODO: implement this
                ( model, Cmd.none )

            ( _, _ ) ->
                -- Disregard incoming messages that arrived for the wrong page
                ( model, Cmd.none )


bootstrap : Session -> Maybe Route -> Cmd Msg
bootstrap session maybeRoute =
    Http.send (AppStateLoaded maybeRoute) (Query.AppState.request session.apiToken)


navigateTo : Maybe Route -> Model -> ( Model, Cmd Msg )
navigateTo maybeRoute model =
    let
        transition model toMsg task =
            ( { model | isTransitioning = True }
            , Task.attempt toMsg task
            )
    in
        case model.appState of
            NotLoaded ->
                ( model, bootstrap model.session maybeRoute )

            Loaded _ ->
                case maybeRoute of
                    Nothing ->
                        ( { model | page = NotFound }, Cmd.none )

                    Just Route.Conversations ->
                        -- TODO: implement this
                        ( { model | page = Conversations }, Cmd.none )

                    Just (Route.Room slug) ->
                        transition model (RoomLoaded slug) (Page.Room.fetchRoom model.session slug)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.appState of
        NotLoaded ->
            div [ id "app" ] [ text "Loading..." ]

        Loaded appState ->
            div [ id "app" ]
                [ div [ class "sidebar sidebar--left" ]
                    [ spaceSelector appState.space
                    , sideNav model.page appState
                    ]
                , div [ class "sidebar sidebar--right" ]
                    [ identityMenu appState.user
                    , usersList appState
                    ]
                , div [ class "main" ]
                    [ div [ class "top-nav" ]
                        [ input [ type_ "text", class "text-field text-field--muted search-field", placeholder "Search" ] []
                        , button [ class "button button--primary new-conversation-button" ] [ text "New Conversation" ]
                        ]
                    , pageContent model.page
                    ]
                ]


pageContent : Page -> Html Msg
pageContent page =
    case page of
        Conversations ->
            Page.Conversations.view
                |> Html.map ConversationsMsg

        Room model ->
            model
                |> Page.Room.view
                |> Html.map RoomMsg

        Blank ->
            -- TODO: implement this
            div [] []

        NotFound ->
            div [ class "blank-slate" ]
                [ h2 [ class "blank-slate__heading" ]
                    [ text "Hmm, we couldn't find what you were looking for." ]
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


inboxLink : Page -> Html Msg
inboxLink page =
    let
        selectedClass =
            case page of
                Conversations ->
                    "side-nav__item--selected"

                _ ->
                    ""
    in
        a [ class ("side-nav__item " ++ selectedClass), Route.href Route.Conversations ]
            [ span [ class "side-nav__item-name" ] [ text "Inbox" ]
            ]


sideNav : Page -> AppState -> Html Msg
sideNav page appState =
    div [ class "side-nav-container" ]
        [ h3 [ class "side-nav-heading" ] [ text "Conversations" ]
        , div [ class "side-nav" ]
            [ inboxLink page
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Everything" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Drafts" ]
                ]
            ]
        , h3 [ class "side-nav-heading" ] [ text "Rooms" ]
        , roomSubscriptionsList page appState
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


roomSubscriptionsList : Page -> AppState -> Html Msg
roomSubscriptionsList page appState =
    div [ class "side-nav" ] (List.map (roomSubscriptionItem page) appState.roomSubscriptions.edges)


roomSubscriptionItem : Page -> RoomSubscriptionEdge -> Html Msg
roomSubscriptionItem page edge =
    let
        room =
            edge.node.room

        selectedClass =
            case page of
                Room model ->
                    if model.room.id == room.id then
                        "side-nav__item--selected"
                    else
                        ""

                _ ->
                    ""
    in
        a [ class ("side-nav__item side-nav__item--room " ++ selectedClass), Route.href (Route.Room room.id) ]
            [ span [ class "side-nav__item-name" ] [ text room.name ]
            ]



-- UTILS


{-| Generate the display name for a given user.

    displayName { firstName = "Derrick", lastName = "Reimer" } == "Derrick Reimer"

-}
displayName : User -> String
displayName user =
    user.firstName ++ " " ++ user.lastName
