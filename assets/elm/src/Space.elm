module Space exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Navigation
import Process
import Task exposing (Task)
import Time exposing (second)
import Data.Space exposing (Space, SpaceUserRole)
import Data.Setup as Setup
import Data.User exposing (UserConnection, User, UserEdge, displayName)
import Page.Inbox
import Page.Setup.CreateGroups
import Page.Setup.InviteUsers
import Ports
import Query.InitSpace
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
    { spaceId : String
    , session : Session
    , sharedState : Lazy SharedState
    , page : Page
    , isTransitioning : Bool
    , flashNotice : Maybe String
    }


type alias SharedState =
    { space : Space
    , user : User
    , setupState : Setup.State
    , openInvitationUrl : Maybe String
    , role : Maybe SpaceUserRole
    }


type Page
    = Blank
    | NotFound
    | Inbox
    | SetupCreateGroups Page.Setup.CreateGroups.Model
    | SetupInviteUsers Page.Setup.InviteUsers.Model


type alias Flags =
    { apiToken : String
    , spaceId : String
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
    Model flags.spaceId (Session.init flags.apiToken) NotLoaded Blank True Nothing


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
    | SharedStateLoaded (Maybe Route) (Result Session.Error ( Session, Query.InitSpace.Response ))
    | InboxMsg Page.Inbox.Msg
    | SetupCreateGroupsMsg Page.Setup.CreateGroups.Msg
    | SetupInviteUsersMsg Page.Setup.InviteUsers.Msg
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

            ( SharedStateLoaded maybeRoute (Ok ( session, response )), _ ) ->
                { model | sharedState = Loaded response, session = session }
                    |> updatePipeline [ navigateTo maybeRoute, setupSockets ]

            ( SharedStateLoaded maybeRoute (Err Session.Expired), _ ) ->
                ( model, Route.toLogin )

            ( SharedStateLoaded maybeRoute (Err _), _ ) ->
                ( model, Cmd.none )

            ( InboxMsg _, _ ) ->
                -- TODO: implement this
                ( model, Cmd.none )

            ( SetupCreateGroupsMsg msg, SetupCreateGroups pageModel ) ->
                let
                    ( ( newPageModel, cmd ), session, externalMsg ) =
                        Page.Setup.CreateGroups.update msg model.session pageModel

                    newModel =
                        case externalMsg of
                            Page.Setup.CreateGroups.SetupStateChanged newState ->
                                updateSetupState newState model

                            Page.Setup.CreateGroups.NoOp ->
                                model
                in
                    ( { newModel
                        | session = session
                        , page = SetupCreateGroups newPageModel
                      }
                    , Cmd.map SetupCreateGroupsMsg cmd
                    )

            ( SetupInviteUsersMsg msg, SetupInviteUsers pageModel ) ->
                let
                    ( ( newPageModel, cmd ), session, externalMsg ) =
                        Page.Setup.InviteUsers.update msg model.session pageModel

                    newModel =
                        case externalMsg of
                            Page.Setup.InviteUsers.SetupStateChanged newState ->
                                updateSetupState newState model

                            Page.Setup.InviteUsers.NoOp ->
                                model
                in
                    ( { newModel
                        | session = session
                        , page = SetupInviteUsers newPageModel
                      }
                    , Cmd.map SetupInviteUsersMsg cmd
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


bootstrap : String -> Session -> Maybe Route -> Cmd Msg
bootstrap spaceId session maybeRoute =
    Query.InitSpace.request (Query.InitSpace.Params spaceId)
        |> Session.request session
        |> Task.attempt (SharedStateLoaded maybeRoute)


navigateTo : Maybe Route -> Model -> ( Model, Cmd Msg )
navigateTo maybeRoute model =
    let
        transition model toMsg task =
            ( { model | isTransitioning = True }
            , Task.attempt toMsg task
            )
    in
        case model.sharedState of
            NotLoaded ->
                ( model, bootstrap model.spaceId model.session maybeRoute )

            Loaded sharedState ->
                case maybeRoute of
                    Nothing ->
                        ( { model | page = NotFound }, Cmd.none )

                    Just Route.Root ->
                        case sharedState.role of
                            Just Data.Space.Owner ->
                                case sharedState.setupState of
                                    Setup.CreateGroups ->
                                        navigateTo (Just Route.SetupCreateGroups) model

                                    Setup.InviteUsers ->
                                        navigateTo (Just Route.SetupInviteUsers) model

                                    Setup.Complete ->
                                        navigateTo (Just Route.Inbox) model

                            _ ->
                                navigateTo (Just Route.Inbox) model

                    Just Route.Inbox ->
                        -- TODO: implement this
                        ( { model | page = Inbox }, Cmd.none )

                    Just Route.SetupCreateGroups ->
                        let
                            pageModel =
                                Page.Setup.CreateGroups.buildModel sharedState.space.id sharedState.user.firstName
                        in
                            ( { model | page = SetupCreateGroups pageModel }
                            , Cmd.none
                            )

                    Just Route.SetupInviteUsers ->
                        let
                            pageModel =
                                Page.Setup.InviteUsers.buildModel sharedState.space.id sharedState.openInvitationUrl
                        in
                            ( { model | page = SetupInviteUsers pageModel }
                            , Cmd.none
                            )


setupSockets : Model -> ( Model, Cmd Msg )
setupSockets model =
    case model.sharedState of
        NotLoaded ->
            ( model, Cmd.none )

        Loaded state ->
            ( model, Cmd.none )


updateSetupState : Setup.State -> Model -> Model
updateSetupState state model =
    case model.sharedState of
        NotLoaded ->
            model

        Loaded sharedState ->
            { model | sharedState = Loaded { sharedState | setupState = state } }



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
    case model.sharedState of
        NotLoaded ->
            text ""

        Loaded sharedState ->
            div []
                [ leftSidebar sharedState model
                , pageContent model.page
                ]


leftSidebar : SharedState -> Model -> Html Msg
leftSidebar sharedState model =
    div [ class "fixed bg-grey-light border-r w-48 h-full min-h-screen p-4" ]
        [ div [ class "ml-2" ]
            [ spaceAvatar sharedState.space
            , div [ class "mb-6 font-extrabold text-lg text-dusty-blue-darker tracking-semi-tight" ] [ text sharedState.space.name ]
            ]
        , ul [ class "list-reset leading-semi-loose select-none" ]
            [ sidebarLink "Inbox" (Just Route.Inbox) model.page
            , sidebarLink "Everything" Nothing model.page
            , sidebarLink "Drafts" Nothing model.page
            ]
        , div [ class "absolute pin-b mb-2 flex" ]
            [ div [] [ userAvatar sharedState.user ]
            , div [ class "ml-2 -mt-1 text-sm text-dusty-blue-darker leading-normal" ]
                [ div [] [ text "Signed in as" ]
                , div [ class "font-bold" ] [ text (displayName sharedState.user) ]
                ]
            ]
        ]


{-| Build a link for the sidebar navigation with a special indicator for the
current page. Pass Nothing for the route to make it a placeholder link.
-}
sidebarLink : String -> Maybe Route -> Page -> Html Msg
sidebarLink title maybeRoute currentPage =
    case maybeRoute of
        Just route ->
            if route == routeFor currentPage then
                li [ class "flex items-center font-bold" ]
                    [ div [ class "-ml-1 w-1 h-5 bg-turquoise rounded-full" ] []
                    , a
                        [ Route.href route
                        , class "ml-2 text-dusty-blue-darker no-underline"
                        ]
                        [ text title ]
                    ]
            else
                li []
                    [ a
                        [ Route.href route
                        , class "ml-2 text-dusty-blue-darker no-underline"
                        ]
                        [ text title ]
                    ]

        Nothing ->
            li []
                [ a
                    [ href "#"
                    , class "ml-2 text-dusty-blue-darker no-underline"
                    ]
                    [ text title ]
                ]


spaceAvatar : Space -> Html Msg
spaceAvatar space =
    space.name
        |> String.left 1
        |> String.toUpper
        |> texitar


userAvatar : User -> Html Msg
userAvatar user =
    user.firstName
        |> String.left 1
        |> String.toUpper
        |> texitar


texitar : String -> Html Msg
texitar initials =
    div [ class "texitar mb-2" ] [ text initials ]


pageContent : Page -> Html Msg
pageContent page =
    case page of
        Inbox ->
            Page.Inbox.view
                |> Html.map InboxMsg

        SetupCreateGroups pageModel ->
            pageModel
                |> Page.Setup.CreateGroups.view
                |> Html.map SetupCreateGroupsMsg

        SetupInviteUsers pageModel ->
            pageModel
                |> Page.Setup.InviteUsers.view
                |> Html.map SetupInviteUsersMsg

        Blank ->
            text ""

        NotFound ->
            text "404"


routeFor : Page -> Route
routeFor page =
    case page of
        Inbox ->
            Route.Inbox

        SetupCreateGroups _ ->
            Route.SetupCreateGroups

        SetupInviteUsers _ ->
            Route.SetupInviteUsers

        Blank ->
            Route.Inbox

        NotFound ->
            Route.Inbox



-- MESSAGE DECODERS


type Message
    = UnknownMessage


decodeMessage : Decode.Value -> Message
decodeMessage value =
    UnknownMessage
