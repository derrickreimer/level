module Main exposing (..)

import Color
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Navigation
import Process
import Task exposing (Task)
import Time exposing (second)
import Data.Room exposing (Room, RoomSubscriptionConnection, RoomSubscriptionEdge)
import Data.Space exposing (Space)
import Data.User exposing (UserConnection, User, UserEdge, displayName)
import Icons exposing (privacyIcon)
import Page.Room
import Page.NewRoom
import Page.RoomSettings
import Page.Conversations
import Page.NewInvitation
import Ports
import Query.AppState
import Query.Room
import Query.RoomSettings
import Route exposing (Route)
import Session exposing (Session)
import Subscription.RoomMessageCreated
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
    , roomSubscriptions : RoomSubscriptionConnection
    , users : UserConnection
    }


type Page
    = Blank
    | NotFound
    | Conversations -- TODO: add a model to this type
    | Room Page.Room.Model
    | NewRoom Page.NewRoom.Model
    | RoomSettings Page.RoomSettings.Model
    | NewInvitation Page.NewInvitation.Model


type alias Flags =
    { csrfToken : String
    , apiToken : String
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
    Model (Session.init flags.csrfToken flags.apiToken) NotLoaded Blank True Nothing


{-| Takes a list of functions from a model to ( model, Cmd msg ) and call them in
succession. Returns a ( model, Cmd msg ), where the Cmd is a batch of accumulated
commands and the model is the original model with all mutations applied to it.
-}
commandPipeline : List (model -> ( model, Cmd msg )) -> model -> ( model, Cmd msg )
commandPipeline transforms model =
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
    | RoomLoaded String (Result Session.Error ( Session, Query.Room.Response ))
    | RoomSettingsLoaded String (Result Session.Error ( Session, Query.RoomSettings.Response ))
    | ConversationsMsg Page.Conversations.Msg
    | RoomMsg Page.Room.Msg
    | NewRoomMsg Page.NewRoom.Msg
    | RoomSettingsMsg Page.RoomSettings.Msg
    | NewInvitationMsg Page.NewInvitation.Msg
    | SendFrame Ports.Frame
    | StartFrameReceived Decode.Value
    | ResultFrameReceived Decode.Value
    | SocketError Decode.Value
    | SocketReset Decode.Value
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
                    |> commandPipeline [ navigateTo maybeRoute, setupSockets ]

            ( AppStateLoaded maybeRoute (Err Session.Expired), _ ) ->
                ( model, Route.toLogin )

            ( AppStateLoaded maybeRoute (Err _), _ ) ->
                ( model, Cmd.none )

            ( RoomLoaded slug (Ok ( session, response )), _ ) ->
                case response of
                    Query.Room.Found data ->
                        ( { model
                            | page = Room (Page.Room.buildModel data)
                            , session = session
                            , isTransitioning = False
                          }
                        , Cmd.map RoomMsg Page.Room.loaded
                        )

                    Query.Room.NotFound ->
                        ( { model
                            | page = NotFound
                            , session = session
                            , isTransitioning = False
                          }
                        , Cmd.none
                        )

            ( RoomLoaded slug (Err Session.Expired), _ ) ->
                ( model, Route.toLogin )

            ( RoomLoaded slug (Err _), _ ) ->
                -- TODO: display an unexpected error page?
                ( model, Cmd.none )

            ( RoomSettingsLoaded slug (Ok ( session, response )), _ ) ->
                case response of
                    Query.RoomSettings.Found data ->
                        ( { model
                            | page = RoomSettings (Page.RoomSettings.buildModel data.room data.users)
                            , session = session
                            , isTransitioning = False
                          }
                        , Cmd.none
                        )

                    Query.RoomSettings.NotFound ->
                        ( { model
                            | page = NotFound
                            , session = session
                            , isTransitioning = False
                          }
                        , Cmd.none
                        )

            ( RoomSettingsLoaded slug (Err Session.Expired), _ ) ->
                ( model, Route.toLogin )

            ( RoomSettingsLoaded slug (Err _), _ ) ->
                -- TODO: display an unexpected error page?
                ( model, Cmd.none )

            ( ConversationsMsg _, _ ) ->
                -- TODO: implement this
                ( model, Cmd.none )

            ( RoomMsg msg, Room pageModel ) ->
                let
                    ( ( newPageModel, cmd ), externalMsg ) =
                        Page.Room.update msg model.session pageModel

                    ( newModel, externalCmd ) =
                        case externalMsg of
                            Page.Room.SessionRefreshed session ->
                                ( { model | session = session }, Cmd.none )

                            Page.Room.ExternalNoOp ->
                                ( model, Cmd.none )
                in
                    ( { newModel | page = Room newPageModel }
                    , Cmd.batch [ externalCmd, Cmd.map RoomMsg cmd ]
                    )

            ( NewRoomMsg msg, NewRoom pageModel ) ->
                let
                    ( ( newPageModel, cmd ), externalMsg ) =
                        Page.NewRoom.update msg model.session pageModel

                    ( newModel, externalCmd ) =
                        case externalMsg of
                            Page.NewRoom.RoomCreated session roomSubscription ->
                                case model.appState of
                                    Loaded appState ->
                                        let
                                            newEdges =
                                                { node = roomSubscription } :: appState.roomSubscriptions.edges

                                            newAppState =
                                                { appState | roomSubscriptions = { edges = newEdges } }
                                        in
                                            ( { model | appState = Loaded newAppState, session = session }, Cmd.none )

                                    NotLoaded ->
                                        ( { model | session = session }, Cmd.none )

                            Page.NewRoom.SessionRefreshed session ->
                                ( { model | session = session }, Cmd.none )

                            Page.NewRoom.NoOp ->
                                ( model, Cmd.none )
                in
                    ( { newModel | page = NewRoom newPageModel }
                    , Cmd.batch [ externalCmd, Cmd.map NewRoomMsg cmd ]
                    )

            ( RoomSettingsMsg msg, RoomSettings pageModel ) ->
                let
                    ( ( newPageModel, cmd ), externalMsg ) =
                        Page.RoomSettings.update msg model.session pageModel

                    ( newModel, externalCmd ) =
                        case externalMsg of
                            Page.RoomSettings.RoomUpdated session room ->
                                let
                                    newModel =
                                        model
                                            |> setFlashNotice "Room updated"
                                            |> updateRoom room
                                in
                                    ( { newModel | session = session }, expireFlashNotice )

                            Page.RoomSettings.SessionRefreshed session ->
                                ( { model | session = session }, Cmd.none )

                            Page.RoomSettings.NoOp ->
                                ( model, Cmd.none )
                in
                    ( { newModel | page = RoomSettings newPageModel }
                    , Cmd.batch [ externalCmd, Cmd.map RoomSettingsMsg cmd ]
                    )

            ( NewInvitationMsg msg, NewInvitation pageModel ) ->
                let
                    ( ( newPageModel, cmd ), externalMsg ) =
                        Page.NewInvitation.update msg model.session pageModel

                    ( newModel, externalCmd ) =
                        case externalMsg of
                            Page.NewInvitation.InvitationCreated session _ ->
                                let
                                    newModel =
                                        { model | session = session }
                                            |> setFlashNotice "Invitation sent"
                                in
                                    ( newModel, expireFlashNotice )

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

            ( StartFrameReceived value, _ ) ->
                ( model, Cmd.none )

            ( ResultFrameReceived value, page ) ->
                case decodeMessage value of
                    RoomMessageCreated result ->
                        case page of
                            Room pageModel ->
                                if pageModel.room.id == result.roomId then
                                    let
                                        ( ( newPageModel, cmd ), _ ) =
                                            Page.Room.receiveMessage result.roomMessage pageModel
                                    in
                                        ( { model | page = Room newPageModel }, Cmd.map RoomMsg cmd )
                                else
                                    ( model, Cmd.none )

                            _ ->
                                ( model, Cmd.none )

                    UnknownMessage ->
                        ( model, Cmd.none )

            ( SocketError value, _ ) ->
                -- Debug.log (Encode.encode 0 value) ( model, Cmd.none )
                let
                    cmd =
                        model.session
                            |> Session.fetchNewToken
                            |> Task.attempt SessionRefreshed
                in
                    ( model, cmd )

            ( SocketReset _, _ ) ->
                setupSockets model

            ( SessionRefreshed (Ok session), _ ) ->
                ( { model | session = session }, Ports.refreshToken session.token )

            ( SessionRefreshed (Err Session.Expired), _ ) ->
                ( model, Route.toLogin )

            ( FlashNoticeExpired, _ ) ->
                ( { model | flashNotice = Nothing }, Cmd.none )

            ( _, _ ) ->
                -- Disregard incoming messages that arrived for the wrong page
                ( model, Cmd.none )


{-| Propagates changes made to room to all the places where that room might be
stored in the model.
-}
updateRoom : Room -> Model -> Model
updateRoom room model =
    case model.appState of
        Loaded data ->
            let
                roomSubscriptions =
                    data.roomSubscriptions

                edges =
                    roomSubscriptions.edges

                update edge =
                    if room.id == edge.node.room.id then
                        let
                            node =
                                edge.node
                        in
                            { edge | node = { node | room = room } }
                    else
                        edge

                newRoomSubscriptions =
                    { roomSubscriptions | edges = List.map update edges }

                newData =
                    { data | roomSubscriptions = newRoomSubscriptions }
            in
                { model | appState = Loaded newData }

        NotLoaded ->
            model


setFlashNotice : String -> Model -> Model
setFlashNotice message model =
    { model | flashNotice = Just message }


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

                    Just (Route.Room slug) ->
                        Page.Room.fetchRoom slug
                            |> Session.request model.session
                            |> transition model (RoomLoaded slug)

                    Just Route.NewRoom ->
                        let
                            pageModel =
                                Page.NewRoom.buildModel
                        in
                            ( { model | page = NewRoom pageModel }
                            , Cmd.map NewRoomMsg Page.NewRoom.initialCmd
                            )

                    Just (Route.RoomSettings slug) ->
                        case model.page of
                            Room currentPageModel ->
                                let
                                    pageModel =
                                        Page.RoomSettings.buildModel currentPageModel.room currentPageModel.users
                                in
                                    ( { model | page = RoomSettings pageModel }, Cmd.none )

                            _ ->
                                Page.RoomSettings.fetchRoomSettings slug
                                    |> Session.request model.session
                                    |> transition model (RoomSettingsLoaded slug)

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
            let
                operation =
                    Subscription.RoomMessageCreated.operation

                variables =
                    Just (Subscription.RoomMessageCreated.variables { user = state.user })
            in
                ( model, Ports.sendFrame <| Ports.Frame operation variables )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.startFrameReceived StartFrameReceived
        , Ports.resultFrameReceived ResultFrameReceived
        , Ports.socketError SocketError
        , Ports.socketReset SocketReset
        , pageSubscription model
        ]


pageSubscription : Model -> Sub Msg
pageSubscription model =
    case model.page of
        Room pageModel ->
            Sub.map RoomMsg <| Page.Room.subscriptions pageModel

        RoomSettings _ ->
            Sub.map RoomSettingsMsg <| Page.RoomSettings.subscriptions

        _ ->
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
                            [ button [ class "button button--primary button--short button--convo" ]
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

        Room model ->
            model
                |> Page.Room.view
                |> Html.map RoomMsg

        NewRoom model ->
            model
                |> Page.NewRoom.view
                |> Html.map NewRoomMsg

        RoomSettings model ->
            model
                |> Page.RoomSettings.view
                |> Html.map RoomSettingsMsg

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
    , roomSubscriptionsList page appState
    ]


rightSidebar : Model -> List (Html Msg)
rightSidebar model =
    case model.page of
        Room pageModel ->
            userList "Members" model.page pageModel.users

        NewRoom _ ->
            mainDirectory model

        RoomSettings pageModel ->
            userList "Members" model.page pageModel.users

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


roomSubscriptionsList : Page -> AppState -> Html Msg
roomSubscriptionsList page appState =
    let
        rooms =
            List.map (roomSubscriptionItem page) appState.roomSubscriptions.edges
    in
        div [ class "side-nav" ] (rooms ++ [ createRoomLink page ])


createRoomLink : Page -> Html Msg
createRoomLink page =
    let
        isActive =
            case page of
                NewRoom _ ->
                    True

                _ ->
                    False
    in
        a
            [ classList
                [ ( "side-nav__item", True )
                , ( "side-nav__item--action", True )
                , ( "side-nav__item--selected", isActive )
                ]
            , Route.href Route.NewRoom
            ]
            [ span [ class "side-nav__item-name" ] [ text "Create a room..." ]
            ]


roomSubscriptionItem : Page -> RoomSubscriptionEdge -> Html Msg
roomSubscriptionItem page edge =
    let
        room =
            edge.node.room

        isActive =
            case page of
                Room pageModel ->
                    if pageModel.room.id == room.id then
                        True
                    else
                        False

                RoomSettings pageModel ->
                    if pageModel.id == room.id then
                        True
                    else
                        False

                _ ->
                    False

        icon =
            case room.subscriberPolicy of
                Data.Room.InviteOnly ->
                    span [ class "side-nav__item-icon" ] [ privacyIcon (Color.rgb 144 150 162) 12 ]

                _ ->
                    text ""

        -- Placeholder for when we implement "unread" indicator
        dot =
            if True == False then
                span [ class "side-nav__item-indicator" ]
                    [ span [ class "side-nav__dot" ] []
                    ]
            else
                text ""
    in
        a
            [ classList
                [ ( "side-nav__item", True )
                , ( "side-nav__item--room", True )
                , ( "side-nav__item--selected", isActive )
                ]
            , Route.href (Route.Room room.id)
            ]
            [ span [ class "side-nav__item-name" ] [ text room.name ]
            , icon
            , dot
            ]



-- MESSAGE DECODERS


type Message
    = RoomMessageCreated Subscription.RoomMessageCreated.Result
    | UnknownMessage


decodeMessage : Decode.Value -> Message
decodeMessage value =
    Decode.decodeValue messageDecoder value
        |> Result.withDefault UnknownMessage


messageDecoder : Decode.Decoder Message
messageDecoder =
    Decode.oneOf
        [ roomMessageCreatedDecoder
        ]


roomMessageCreatedDecoder : Decode.Decoder Message
roomMessageCreatedDecoder =
    Decode.map RoomMessageCreated Subscription.RoomMessageCreated.decoder
