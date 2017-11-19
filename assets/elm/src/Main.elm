port module Main exposing (..)

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
        |> assembleBatch
            [ navigateTo (Route.fromLocation location)
            , setupSockets
            ]


{-| Build the initial model, before running the page "bootstrap" query.
-}
buildInitialModel : Flags -> Model
buildInitialModel flags =
    Model (Session flags.apiToken) NotLoaded Blank True


{-| Take a list of functions that accept a model and return a ( Model, Cmd Msg )
tuple, call them in succession, and return a ( Model, Cmd Msg ), where the
command is a batch of accumulated commands.
-}
assembleBatch :
    List (Model -> ( Model, Cmd Msg ))
    -> Model
    -> ( Model, Cmd Msg )
assembleBatch transforms model =
    let
        reducer transform ( model, cmds ) =
            transform model
                |> Tuple.mapSecond (\cmd -> cmd :: cmds)
    in
        List.foldr reducer ( model, [] ) transforms
            |> Tuple.mapSecond Cmd.batch



-- UPDATE


type Msg
    = UrlChanged Navigation.Location
    | AppStateLoaded (Maybe Route) (Result Http.Error Query.AppState.Response)
    | RoomLoaded String (Result Http.Error Query.Room.Response)
    | ConversationsMsg Page.Conversations.Msg
    | RoomMsg Page.Room.Msg
    | SendFrame String
    | FrameReceived String


getSession : Model -> Session
getSession model =
    model.session


getPage : Model -> Page
getPage model =
    model.page


port sendFrame : String -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                ( { model | page = toModel newModel }, Cmd.map toMsg newCmd )
    in
        case ( msg, model.page ) of
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
                        , Cmd.map RoomMsg Page.Room.loaded
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
                let
                    ( newPageModel, cmd ) =
                        Page.Room.update msg model.session pageModel
                in
                    ( { model | page = Room newPageModel }, Cmd.map RoomMsg cmd )

            ( SendFrame payload, _ ) ->
                ( model, sendFrame payload )

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


setupSockets : Model -> ( Model, Cmd Msg )
setupSockets model =
    let
        -- TODO: replace this with a generic subscription
        operation =
            """
              subscription {
                roomMessageCreated(roomId: "51077027888890883") {
                  roomMessage {
                    body
                  }
                }
              }
            """
    in
        ( model, sendFrame operation )



-- SUBSCRIPTIONS


port receiveFrame : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    receiveFrame FrameReceived



-- VIEW


view : Model -> Html Msg
view model =
    case model.appState of
        NotLoaded ->
            div [ id "app" ] [ text "Loading..." ]

        Loaded appState ->
            div [ id "app" ]
                [ div [ id "sidebar-left", class "sidebar" ]
                    [ spaceSelector appState.space
                    , div [ class "sidebar__button-container" ]
                        [ button [ class "button button--primary new-conversation-button" ] [ text "New Conversation" ]
                        ]
                    , sideNav model.page appState
                    ]
                , div [ id "sidebar-right", class "sidebar" ]
                    [ identityMenu appState.user
                    , usersList appState
                    ]
                , pageContent model.page
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
                [ div [ class "identity-menu__name" ] [ text (Data.User.displayName user) ]
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
        [ div [ class "side-nav" ]
            [ inboxLink page
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Everything" ]
                ]
            , a [ class "side-nav__item", href "#" ]
                [ span [ class "side-nav__item-name" ] [ text "Drafts" ]
                ]
            ]
        , roomSubscriptionsList page appState
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
