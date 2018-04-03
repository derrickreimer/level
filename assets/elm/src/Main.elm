module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Navigation
import Process
import Task exposing (Task)
import Time exposing (second)
import Data.Space exposing (Space)
import Data.User exposing (UserConnection, User, UserEdge, displayName)
import Page.Conversations
import Page.NewInvitation
import Ports
import Query.AppState
import Route exposing (Route)
import Session exposing (Session)
import Util exposing (Lazy(..))


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChanged
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { session : Session
    , appState : Lazy AppState
    , page : Page
    , isTransitioning : Bool
    , flashNotice : Maybe String
    }


type alias AppState =
    { space : Space
    , user : User
    , users : UserConnection
    }


type Page
    = Blank
    | NotFound
    | Conversations -- TODO: add a model to this type
    | NewInvitation Page.NewInvitation.Model


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
        |> buildModel
        |> navigateTo (Route.fromLocation location)


{-| Build the initial model, before running the page "bootstrap" query.
-}
buildModel : Flags -> Model
buildModel flags =
    Model (Session.init flags.apiToken) NotLoaded Blank True Nothing


{-| Takes a list of functions from a model to ( model, Cmd msg ) and call them in
succession. Returns a ( model, Cmd msg ), where the Cmd is a batch of accumulated
commands and the model is the original model with all mutations applied to it.
-}
updatePipeline : List (model -> ( model, Cmd msg )) -> model -> ( model, Cmd msg )
updatePipeline transforms model =
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
    | AppStateLoaded (Maybe Route) (Result Session.Error ( Session, Query.AppState.Response ))
    | ConversationsMsg Page.Conversations.Msg
    | NewInvitationMsg Page.NewInvitation.Msg
    | SendFrame Ports.Frame
    | SocketAbort Decode.Value
    | SocketStart Decode.Value
    | SocketResult Decode.Value
    | SocketError Decode.Value
    | SocketTokenUpdated Decode.Value
    | SessionRefreshed (Result Session.Error Session)
    | FlashNoticeExpired


getPage : Model -> Page
getPage model =
    model.page


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

            ( AppStateLoaded maybeRoute (Ok ( session, response )), _ ) ->
                { model | appState = Loaded response, session = session }
                    |> updatePipeline [ navigateTo maybeRoute, setupSockets ]

            ( AppStateLoaded maybeRoute (Err Session.Expired), _ ) ->
                ( model, Route.toLogin )

            ( AppStateLoaded maybeRoute (Err _), _ ) ->
                ( model, Cmd.none )

            ( ConversationsMsg _, _ ) ->
                -- TODO: implement this
                ( model, Cmd.none )

            ( NewInvitationMsg msg, NewInvitation pageModel ) ->
                let
                    ( ( newPageModel, cmd ), externalMsg ) =
                        Page.NewInvitation.update msg model.session pageModel

                    ( newModel, externalCmd ) =
                        case externalMsg of
                            Page.NewInvitation.InvitationCreated session _ ->
                                { model | session = session }
                                    |> updatePipeline [ setFlashNotice "Invitation sent" ]

                            Page.NewInvitation.SessionRefreshed session ->
                                ( { model | session = session }, Cmd.none )

                            Page.NewInvitation.NoOp ->
                                ( model, Cmd.none )
                in
                    ( { newModel | page = NewInvitation newPageModel }
                    , Cmd.batch [ externalCmd, Cmd.map NewInvitationMsg cmd ]
                    )

            ( SendFrame frame, _ ) ->
                ( model, Ports.sendFrame frame )

            ( SocketAbort value, _ ) ->
                ( model, Cmd.none )

            ( SocketStart value, _ ) ->
                ( model, Cmd.none )

            ( SocketResult value, page ) ->
                case decodeMessage value of
                    UnknownMessage ->
                        ( model, Cmd.none )

            ( SocketError value, _ ) ->
                let
                    cmd =
                        model.session
                            |> Session.fetchNewToken
                            |> Task.attempt SessionRefreshed
                in
                    ( model, cmd )

            ( SocketTokenUpdated _, _ ) ->
                ( model, Cmd.none )

            ( SessionRefreshed (Ok session), _ ) ->
                ( { model | session = session }, Ports.updateToken session.token )

            ( SessionRefreshed (Err Session.Expired), _ ) ->
                ( model, Route.toLogin )

            ( FlashNoticeExpired, _ ) ->
                ( { model | flashNotice = Nothing }, Cmd.none )

            ( _, _ ) ->
                -- Disregard incoming messages that arrived for the wrong page
                ( model, Cmd.none )



setFlashNotice : String -> Model -> ( Model, Cmd Msg )
setFlashNotice message model =
    ( { model | flashNotice = Just message }, expireFlashNotice )


expireFlashNotice : Cmd Msg
expireFlashNotice =
    Task.perform (\_ -> FlashNoticeExpired) <| Process.sleep (3 * second)


bootstrap : Session -> Maybe Route -> Cmd Msg
bootstrap session maybeRoute =
    Query.AppState.request
        |> Session.request session
        |> Task.attempt (AppStateLoaded maybeRoute)


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

                    Just Route.NewInvitation ->
                        let
                            pageModel =
                                Page.NewInvitation.buildModel
                        in
                            ( { model | page = NewInvitation pageModel }
                            , Cmd.map NewInvitationMsg (Page.NewInvitation.initialCmd model.session)
                            )


setupSockets : Model -> ( Model, Cmd Msg )
setupSockets model =
    case model.appState of
        NotLoaded ->
            ( model, Cmd.none )

        Loaded state ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.socketAbort SocketAbort
        , Ports.socketStart SocketStart
        , Ports.socketResult SocketResult
        , Ports.socketError SocketError
        , Ports.socketTokenUpdated SocketTokenUpdated
        , pageSubscription model
        ]


pageSubscription : Model -> Sub Msg
pageSubscription model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.appState of
        NotLoaded ->
            div [ id "cockpit" ] [ text "Loading..." ]

        Loaded appState ->
            div [ id "cockpit" ]
                [ div [ id "sidebar-left", class "sidebar sidebar-left" ]
                    [ div [ class "sidebar-left__head" ]
                        [ spaceSelector appState.space
                        , div [ class "sidebar__button-container" ]
                            [ button [ class "button button--subdued button--short button--convo" ]
                                [ text "New Conversation"
                                ]
                            ]
                        ]
                    , div [ class "sidebar-left__nav" ] (sideNav model.page appState)
                    ]
                , div [ id "sidebar-right", class "sidebar sidebar-right" ]
                    [ div [ class "sidebar-right__head" ] [ identityMenu appState.user ]
                    , div [ class "sidebar-right__nav" ] (rightSidebar model)
                    ]
                , pageContent model.page
                , flashNotice model
                ]


flashNotice : Model -> Html Msg
flashNotice model =
    case model.flashNotice of
        Just message ->
            div [ class "flash flash--notice" ] [ text message ]

        Nothing ->
            text ""


pageContent : Page -> Html Msg
pageContent page =
    case page of
        Conversations ->
            Page.Conversations.view
                |> Html.map ConversationsMsg

        NewInvitation model ->
            model
                |> Page.NewInvitation.view
                |> Html.map NewInvitationMsg

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


stubbedAvatarUrl : String
stubbedAvatarUrl =
    "https://pbs.twimg.com/profile_images/952064552287453185/T_QMnFac_400x400.jpg"


identityMenu : User -> Html Msg
identityMenu user =
    div [ class "identity-menu" ]
        [ a [ class "identity-menu__toggle", href "#" ]
            [ img [ class "identity-menu__avatar", src stubbedAvatarUrl ] []
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


sideNav : Page -> AppState -> List (Html Msg)
sideNav page appState =
    [ div [ class "side-nav" ]
        [ inboxLink page
        , a [ class "side-nav__item", href "#" ]
            [ span [ class "side-nav__item-name" ] [ text "Everything" ]
            ]
        , a [ class "side-nav__item", href "#" ]
            [ span [ class "side-nav__item-name" ] [ text "Drafts" ]
            ]
        ]
    ]


rightSidebar : Model -> List (Html Msg)
rightSidebar model =
    case model.page of
        Conversations ->
            mainDirectory model

        NewInvitation _ ->
            mainDirectory model

        _ ->
            []


mainDirectory : Model -> List (Html Msg)
mainDirectory model =
    let
        isInviteActive =
            case model.page of
                NewInvitation _ ->
                    True

                _ ->
                    False

        inviteLink =
            div [ class "side-nav side-nav--right" ]
                [ a
                    [ classList
                        [ ( "side-nav__item", True )
                        , ( "side-nav__item--action", True )
                        , ( "side-nav__item--selected", isInviteActive )
                        ]
                    , Route.href Route.NewInvitation
                    ]
                    [ span [ class "side-nav__item-name" ] [ text "Invite people..." ] ]
                ]
    in
        case model.appState of
            Loaded appState ->
                (userList "Directory" model.page appState.users) ++ [ inviteLink ]

            NotLoaded ->
                []


userList : String -> Page -> UserConnection -> List (Html Msg)
userList heading page users =
    [ h3 [ class "side-nav-heading" ] [ text heading ]
    , div [ class "side-nav side-nav--right" ] (List.map (userItem page) users.edges)
    ]


userItem : Page -> UserEdge -> Html Msg
userItem page edge =
    a [ class "side-nav__item", href "#" ]
        [ span [ class "side-nav__state-indicator side-nav__state-indicator--available" ] []
        , span [ class "side-nav__item-name" ] [ text (displayName edge.node) ]
        ]


-- MESSAGE DECODERS


type Message
    = UnknownMessage


decodeMessage : Decode.Value -> Message
decodeMessage value =
    UnknownMessage
