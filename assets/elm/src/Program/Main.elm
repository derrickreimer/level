module Program.Main exposing (main)

import Avatar exposing (personAvatar, thingAvatar)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Connection
import Device exposing (Device)
import Event exposing (Event)
import Flash exposing (Flash)
import Globals exposing (Globals)
import Html exposing (..)
import Html.Attributes exposing (..)
import Id exposing (Id)
import Json.Decode as Decode exposing (decodeString)
import Lazy exposing (Lazy(..))
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.RegisterPushSubscription as RegisterPushSubscription
import Mutation.UpdateUser as UpdateUser
import Page.Group
import Page.GroupSettings
import Page.Groups
import Page.Help
import Page.Inbox
import Page.InviteUsers
import Page.NewGroup
import Page.NewSpace
import Page.Post
import Page.Posts
import Page.Search
import Page.Settings
import Page.SpaceUser
import Page.SpaceUsers
import Page.Spaces
import Page.UserSettings
import Page.WelcomeTutorial
import Presence exposing (PresenceList)
import PushManager
import PushStatus exposing (PushStatus)
import Query.GetSpaceUserLists as GetSpaceUserLists
import Query.MainInit as MainInit
import Repo exposing (Repo)
import Response exposing (Response)
import Route exposing (Route)
import Route.Groups
import Route.Inbox
import Session exposing (Session)
import Socket
import SocketState exposing (SocketState(..))
import Space exposing (Space)
import SpaceUserLists exposing (SpaceUserLists)
import Subscription.SpaceSubscription as SpaceSubscription
import Subscription.SpaceUserSubscription as SpaceUserSubscription
import Task exposing (Task)
import Url exposing (Url)
import User exposing (User)
import View.Helpers exposing (viewIf)



-- PROGRAM


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequest
        , onUrlChange = UrlChange
        }



-- MODEL


type alias Model =
    { navKey : Nav.Key
    , session : Session
    , device : Device
    , repo : Repo
    , page : Page
    , isTransitioning : Bool
    , pushStatus : PushStatus
    , socketState : SocketState
    , spaceUserLists : SpaceUserLists
    , currentUser : Lazy User
    , timeZone : String
    , flash : Flash
    }


type alias Flags =
    { apiToken : String
    , supportsNotifications : Bool
    , timeZone : String
    , device : String
    }



-- LIFECYCLE


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        ( model, navigateCmd ) =
            navigateTo (Route.fromUrl url) <|
                buildModel flags navKey

        initCmd =
            model.session
                |> MainInit.request
                |> Task.attempt AppInitialized
    in
    ( model
    , Cmd.batch
        [ navigateCmd
        , initCmd
        , PushManager.getSubscription
        ]
    )


buildModel : Flags -> Nav.Key -> Model
buildModel flags navKey =
    Model
        navKey
        (Session.init flags.apiToken)
        (Device.parse flags.device)
        Repo.empty
        Blank
        True
        (PushStatus.init flags.supportsNotifications)
        SocketState.Unknown
        SpaceUserLists.init
        NotLoaded
        flags.timeZone
        Flash.init


setup : MainInit.Response -> Model -> ( Model, Cmd Msg )
setup { currentUser, spaceIds, spaceUserIds } model =
    let
        subscribeToSpaces =
            Cmd.batch <|
                List.map SpaceSubscription.subscribe spaceIds

        subscribeToSpaceUsers =
            Cmd.batch <|
                List.map SpaceUserSubscription.subscribe spaceUserIds

        getSpaceUserLists =
            model.session
                |> GetSpaceUserLists.request
                |> Task.attempt SpaceUserListsLoaded

        updateTimeZone =
            -- Note: It would be better to present the user with a notice that their
            -- time zone on file differs from the one currently detected in their browser,
            -- and ask if they want to change it.
            if User.timeZone currentUser /= model.timeZone then
                model.session
                    |> UpdateUser.request (UpdateUser.timeZoneVariables model.timeZone)
                    |> Task.attempt TimeZoneUpdated

            else
                Cmd.none
    in
    ( { model | currentUser = Loaded currentUser }
    , Cmd.batch
        [ subscribeToSpaces
        , subscribeToSpaceUsers
        , getSpaceUserLists
        , updateTimeZone
        ]
    )


buildGlobals : Model -> Globals
buildGlobals model =
    { session = model.session
    , repo = model.repo
    , navKey = model.navKey
    , timeZone = model.timeZone
    , flash = model.flash
    , device = model.device
    , pushStatus = model.pushStatus
    , currentRoute = routeFor model.page
    , spaceUserLists = model.spaceUserLists
    }



-- UPDATE


type Msg
    = UrlChange Url
    | UrlRequest UrlRequest
    | AppInitialized (Result Session.Error ( Session, MainInit.Response ))
    | SessionRefreshed (Result Session.Error Session)
    | SpaceUserListsLoaded (Result Session.Error ( Session, GetSpaceUserLists.Response ))
    | TimeZoneUpdated (Result Session.Error ( Session, UpdateUser.Response ))
    | PageInitialized PageInit
    | SpacesMsg Page.Spaces.Msg
    | NewSpaceMsg Page.NewSpace.Msg
    | PostsMsg Page.Posts.Msg
    | InboxMsg Page.Inbox.Msg
    | SpaceUserMsg Page.SpaceUser.Msg
    | SpaceUsersMsg Page.SpaceUsers.Msg
    | InviteUsersMsg Page.InviteUsers.Msg
    | GroupsMsg Page.Groups.Msg
    | GroupMsg Page.Group.Msg
    | NewGroupMsg Page.NewGroup.Msg
    | GroupSettingsMsg Page.GroupSettings.Msg
    | PostMsg Page.Post.Msg
    | UserSettingsMsg Page.UserSettings.Msg
    | SpaceSettingsMsg Page.Settings.Msg
    | SearchMsg Page.Search.Msg
    | WelcomeTutorialMsg Page.WelcomeTutorial.Msg
    | HelpMsg Page.Help.Msg
    | SocketIn Decode.Value
    | PushManagerIn Decode.Value
    | PushSubscriptionRegistered (Result Session.Error ( Session, RegisterPushSubscription.Response ))
    | PresenceIn Decode.Value
    | FlashExpired Flash.Key


updatePage : (a -> Page) -> (b -> Msg) -> Model -> ( a, Cmd b ) -> ( Model, Cmd Msg )
updatePage toPage toPageMsg model ( pageModel, pageCmd ) =
    ( { model | page = toPage pageModel }
    , Cmd.map toPageMsg pageCmd
    )


updatePageWithGlobals : (a -> Page) -> (b -> Msg) -> Model -> ( ( a, Cmd b ), Globals ) -> ( Model, Cmd Msg )
updatePageWithGlobals toPage toPageMsg model ( ( newPageModel, pageCmd ), newGlobals ) =
    let
        ( newFlash, flashCmd ) =
            Flash.startTimer FlashExpired newGlobals.flash
    in
    ( { model
        | session = newGlobals.session
        , repo = newGlobals.repo
        , page = toPage newPageModel
        , flash = newFlash
      }
    , Cmd.batch
        [ Cmd.map toPageMsg pageCmd
        , flashCmd
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        globals =
            buildGlobals model
    in
    case ( msg, model.page ) of
        ( UrlChange url, _ ) ->
            navigateTo (Route.fromUrl url) model

        ( UrlRequest request, _ ) ->
            case request of
                Browser.Internal url ->
                    let
                        urlString =
                            Url.toString url
                    in
                    if String.endsWith "/logout" urlString then
                        ( model, Nav.load urlString )

                    else
                        ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( AppInitialized (Ok ( newSession, response )), _ ) ->
            let
                ( newModel, cmd ) =
                    setup response model
            in
            ( { newModel | session = newSession }, cmd )

        ( AppInitialized (Err Session.Expired), _ ) ->
            ( model, Route.toLogin )

        ( AppInitialized (Err _), _ ) ->
            ( model, Cmd.none )

        ( SessionRefreshed (Ok newSession), _ ) ->
            ( { model | session = newSession }, Session.propagateToken newSession )

        ( SessionRefreshed (Err Session.Expired), _ ) ->
            ( model, Route.toLogin )

        ( SpaceUserListsLoaded (Ok ( newSession, resp )), _ ) ->
            ( { model
                | spaceUserLists = resp.spaceUserLists
                , repo = Repo.union resp.repo model.repo
              }
            , Cmd.none
            )

        ( SpaceUserListsLoaded (Err Session.Expired), _ ) ->
            ( model, Route.toLogin )

        ( SpaceUserListsLoaded (Err _), _ ) ->
            ( model, Cmd.none )

        ( TimeZoneUpdated (Ok ( newSession, UpdateUser.Success newUser )), _ ) ->
            ( { model | currentUser = Loaded newUser, session = newSession }, Cmd.none )

        ( TimeZoneUpdated _, _ ) ->
            ( model, Cmd.none )

        ( PageInitialized pageInit, _ ) ->
            setupPage pageInit model

        ( SpacesMsg pageMsg, Spaces pageModel ) ->
            pageModel
                |> Page.Spaces.update pageMsg globals
                |> updatePageWithGlobals Spaces SpacesMsg model

        ( NewSpaceMsg pageMsg, NewSpace pageModel ) ->
            pageModel
                |> Page.NewSpace.update pageMsg globals model.navKey
                |> updatePageWithGlobals NewSpace NewSpaceMsg model

        ( PostsMsg pageMsg, Posts pageModel ) ->
            pageModel
                |> Page.Posts.update pageMsg globals
                |> updatePageWithGlobals Posts PostsMsg model

        ( InboxMsg pageMsg, Inbox pageModel ) ->
            pageModel
                |> Page.Inbox.update pageMsg globals
                |> updatePageWithGlobals Inbox InboxMsg model

        ( SpaceUserMsg pageMsg, SpaceUser pageModel ) ->
            pageModel
                |> Page.SpaceUser.update pageMsg globals
                |> updatePageWithGlobals SpaceUser SpaceUserMsg model

        ( SpaceUsersMsg pageMsg, SpaceUsers pageModel ) ->
            pageModel
                |> Page.SpaceUsers.update pageMsg globals
                |> updatePageWithGlobals SpaceUsers SpaceUsersMsg model

        ( InviteUsersMsg pageMsg, InviteUsers pageModel ) ->
            pageModel
                |> Page.InviteUsers.update pageMsg globals
                |> updatePageWithGlobals InviteUsers InviteUsersMsg model

        ( GroupsMsg pageMsg, Groups pageModel ) ->
            pageModel
                |> Page.Groups.update pageMsg globals
                |> updatePageWithGlobals Groups GroupsMsg model

        ( GroupMsg pageMsg, Group pageModel ) ->
            pageModel
                |> Page.Group.update pageMsg globals
                |> updatePageWithGlobals Group GroupMsg model

        ( NewGroupMsg pageMsg, NewGroup pageModel ) ->
            pageModel
                |> Page.NewGroup.update pageMsg globals model.navKey
                |> updatePageWithGlobals NewGroup NewGroupMsg model

        ( GroupSettingsMsg pageMsg, GroupSettings pageModel ) ->
            pageModel
                |> Page.GroupSettings.update pageMsg globals
                |> updatePageWithGlobals GroupSettings GroupSettingsMsg model

        ( PostMsg pageMsg, Post pageModel ) ->
            pageModel
                |> Page.Post.update pageMsg globals
                |> updatePageWithGlobals Post PostMsg model

        ( UserSettingsMsg pageMsg, UserSettings pageModel ) ->
            pageModel
                |> Page.UserSettings.update pageMsg globals
                |> updatePageWithGlobals UserSettings UserSettingsMsg model

        ( SpaceSettingsMsg pageMsg, SpaceSettings pageModel ) ->
            pageModel
                |> Page.Settings.update pageMsg globals
                |> updatePageWithGlobals SpaceSettings SpaceSettingsMsg model

        ( SearchMsg pageMsg, Search pageModel ) ->
            pageModel
                |> Page.Search.update pageMsg globals
                |> updatePageWithGlobals Search SearchMsg model

        ( WelcomeTutorialMsg pageMsg, WelcomeTutorial pageModel ) ->
            pageModel
                |> Page.WelcomeTutorial.update pageMsg globals
                |> updatePageWithGlobals WelcomeTutorial WelcomeTutorialMsg model

        ( HelpMsg pageMsg, Help pageModel ) ->
            pageModel
                |> Page.Help.update pageMsg globals
                |> updatePageWithGlobals Help HelpMsg model

        ( SocketIn value, page ) ->
            case Socket.decodeEvent value of
                Socket.MessageReceived messageData ->
                    let
                        event =
                            Event.decodeEvent messageData

                        ( newModel, cmd ) =
                            consumeEvent event model

                        ( newModel2, cmd2 ) =
                            sendEventToPage globals event newModel
                    in
                    ( newModel2, Cmd.batch [ cmd, cmd2 ] )

                Socket.Opened ->
                    ( { model | socketState = SocketState.Open }, Cmd.none )

                Socket.Closed ->
                    ( { model | socketState = SocketState.Closed }, Cmd.none )

                Socket.Unknown ->
                    ( model, Cmd.none )

        ( PushManagerIn value, _ ) ->
            case PushManager.decodePayload value of
                PushManager.Subscription (Just data) ->
                    let
                        cmd =
                            model.session
                                |> RegisterPushSubscription.request data
                                |> Task.attempt PushSubscriptionRegistered
                    in
                    ( { model | pushStatus = PushStatus.setIsSubscribed model.pushStatus }, cmd )

                PushManager.Subscription Nothing ->
                    ( { model | pushStatus = PushStatus.setNotSubscribed model.pushStatus }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ( PushSubscriptionRegistered _, _ ) ->
            ( model, Cmd.none )

        ( PresenceIn value, _ ) ->
            sendPresenceToPage (Presence.decode value) model

        ( FlashExpired key, _ ) ->
            let
                newFlash =
                    Flash.expire key model.flash
            in
            ( { model | flash = newFlash }, Cmd.none )

        ( _, _ ) ->
            -- Disregard incoming messages that arrived for the wrong page
            ( model, Cmd.none )



-- PAGES


type Page
    = Blank
    | NotFound
    | Spaces Page.Spaces.Model
    | NewSpace Page.NewSpace.Model
    | Posts Page.Posts.Model
    | Inbox Page.Inbox.Model
    | SpaceUser Page.SpaceUser.Model
    | SpaceUsers Page.SpaceUsers.Model
    | InviteUsers Page.InviteUsers.Model
    | Groups Page.Groups.Model
    | Group Page.Group.Model
    | NewGroup Page.NewGroup.Model
    | GroupSettings Page.GroupSettings.Model
    | Post Page.Post.Model
    | UserSettings Page.UserSettings.Model
    | SpaceSettings Page.Settings.Model
    | Search Page.Search.Model
    | WelcomeTutorial Page.WelcomeTutorial.Model
    | Help Page.Help.Model


type PageInit
    = SpacesInit (Result Session.Error ( Globals, Page.Spaces.Model ))
    | NewSpaceInit (Result Session.Error ( Globals, Page.NewSpace.Model ))
    | PostsInit (Result Session.Error ( Globals, Page.Posts.Model ))
    | InboxInit (Result Session.Error (Response ( Globals, Page.Inbox.Model )))
    | SpaceUserInit (Result Session.Error ( Globals, Page.SpaceUser.Model ))
    | SpaceUsersInit (Result Session.Error ( Globals, Page.SpaceUsers.Model ))
    | InviteUsersInit (Result Session.Error ( Globals, Page.InviteUsers.Model ))
    | GroupsInit (Result Session.Error ( Globals, Page.Groups.Model ))
    | GroupInit (Result Session.Error ( Globals, Page.Group.Model ))
    | NewGroupInit (Result Session.Error ( Globals, Page.NewGroup.Model ))
    | GroupSettingsInit (Result Session.Error ( Globals, Page.GroupSettings.Model ))
    | PostInit String (Result Session.Error ( Globals, Page.Post.Model ))
    | UserSettingsInit (Result Session.Error ( Globals, Page.UserSettings.Model ))
    | SpaceSettingsInit (Result Session.Error ( Globals, Page.Settings.Model ))
    | SearchInit (Result Session.Error ( Globals, Page.Search.Model ))
    | WelcomeTutorialInit (Result Session.Error ( Globals, Page.WelcomeTutorial.Model ))
    | HelpInit (Result Session.Error ( Globals, Page.Help.Model ))


transition : Model -> (Result x a -> PageInit) -> Task x a -> ( Model, Cmd Msg )
transition model toMsg task =
    ( { model | isTransitioning = True }
    , Cmd.batch
        [ teardownPage model.page
        , Cmd.map PageInitialized <| Task.attempt toMsg task
        ]
    )


navigateTo : Maybe Route -> Model -> ( Model, Cmd Msg )
navigateTo maybeRoute model =
    let
        globals =
            buildGlobals model
    in
    case maybeRoute of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just (Route.Root spaceSlug) ->
            navigateTo (Just <| Route.Inbox (Route.Inbox.init spaceSlug)) model

        Just Route.Spaces ->
            globals
                |> Page.Spaces.init
                |> transition model SpacesInit

        Just Route.NewSpace ->
            globals
                |> Page.NewSpace.init
                |> transition model NewSpaceInit

        Just (Route.Posts params) ->
            globals
                |> Page.Posts.init params
                |> transition model PostsInit

        Just (Route.Inbox params) ->
            globals
                |> Page.Inbox.init params
                |> transition model InboxInit

        Just (Route.SpaceUser params) ->
            globals
                |> Page.SpaceUser.init params
                |> transition model SpaceUserInit

        Just (Route.SpaceUsers params) ->
            globals
                |> Page.SpaceUsers.init params
                |> transition model SpaceUsersInit

        Just (Route.InviteUsers slug) ->
            globals
                |> Page.InviteUsers.init slug
                |> transition model InviteUsersInit

        Just (Route.Groups params) ->
            globals
                |> Page.Groups.init params
                |> transition model GroupsInit

        Just (Route.Group params) ->
            globals
                |> Page.Group.init params
                |> transition model GroupInit

        Just (Route.NewGroup spaceSlug) ->
            globals
                |> Page.NewGroup.init spaceSlug
                |> transition model NewGroupInit

        Just (Route.GroupSettings params) ->
            globals
                |> Page.GroupSettings.init params
                |> transition model GroupSettingsInit

        Just (Route.Post spaceSlug postId) ->
            globals
                |> Page.Post.init spaceSlug postId
                |> transition model (PostInit postId)

        Just (Route.Settings spaceSlug) ->
            globals
                |> Page.Settings.init spaceSlug
                |> transition model SpaceSettingsInit

        Just Route.UserSettings ->
            globals
                |> Page.UserSettings.init
                |> transition model UserSettingsInit

        Just (Route.Search params) ->
            globals
                |> Page.Search.init params
                |> transition model SearchInit

        Just (Route.WelcomeTutorial params) ->
            globals
                |> Page.WelcomeTutorial.init params
                |> transition model WelcomeTutorialInit

        Just (Route.Help params) ->
            globals
                |> Page.Help.init params
                |> transition model HelpInit


pageTitle : Repo -> Page -> String
pageTitle repo page =
    case page of
        Spaces _ ->
            Page.Spaces.title

        NewSpace _ ->
            Page.NewSpace.title

        Posts _ ->
            Page.Posts.title

        Inbox _ ->
            Page.Inbox.title

        SpaceUser _ ->
            Page.SpaceUser.title

        SpaceUsers _ ->
            Page.SpaceUsers.title

        Group pageModel ->
            Page.Group.title repo pageModel

        Groups _ ->
            Page.Groups.title

        NewGroup _ ->
            Page.NewGroup.title

        GroupSettings _ ->
            Page.GroupSettings.title

        Post pageModel ->
            Page.Post.title pageModel

        SpaceSettings _ ->
            Page.Settings.title

        InviteUsers _ ->
            Page.InviteUsers.title

        UserSettings _ ->
            Page.UserSettings.title

        Search pageModel ->
            Page.Search.title pageModel

        WelcomeTutorial pageModel ->
            Page.WelcomeTutorial.title

        Help pageModel ->
            Page.Help.title

        NotFound ->
            "404"

        Blank ->
            "Level"


setupPage : PageInit -> Model -> ( Model, Cmd Msg )
setupPage pageInit model =
    let
        perform setupFn toPage toPageMsg appModel ( newGlobals, pageModel ) =
            ( { appModel
                | page = toPage pageModel
                , session = newGlobals.session
                , repo = newGlobals.repo
                , isTransitioning = False
              }
            , Cmd.map toPageMsg (setupFn pageModel)
            )
    in
    case pageInit of
        SpacesInit (Ok result) ->
            perform Page.Spaces.setup Spaces SpacesMsg model result

        SpacesInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SpacesInit (Err _) ->
            ( model, Cmd.none )

        NewSpaceInit (Ok result) ->
            perform Page.NewSpace.setup NewSpace NewSpaceMsg model result

        NewSpaceInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        NewSpaceInit (Err _) ->
            ( model, Cmd.none )

        InboxInit (Ok (Response.Found ( newGlobals, pageModel ))) ->
            perform (Page.Inbox.setup newGlobals) Inbox InboxMsg model ( newGlobals, pageModel )

        InboxInit (Ok Response.NotFound) ->
            ( { model | page = NotFound }, Cmd.none )

        InboxInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        InboxInit (Err _) ->
            ( model, Cmd.none )

        PostsInit (Ok result) ->
            perform Page.Posts.setup Posts PostsMsg model result

        PostsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        PostsInit (Err _) ->
            ( model, Cmd.none )

        SpaceUserInit (Ok result) ->
            perform Page.SpaceUser.setup SpaceUser SpaceUserMsg model result

        SpaceUserInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SpaceUserInit (Err _) ->
            ( model, Cmd.none )

        SpaceUsersInit (Ok result) ->
            perform Page.SpaceUsers.setup SpaceUsers SpaceUsersMsg model result

        SpaceUsersInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SpaceUsersInit (Err _) ->
            ( model, Cmd.none )

        InviteUsersInit (Ok result) ->
            perform Page.InviteUsers.setup InviteUsers InviteUsersMsg model result

        InviteUsersInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        InviteUsersInit (Err _) ->
            ( model, Cmd.none )

        GroupsInit (Ok result) ->
            perform Page.Groups.setup Groups GroupsMsg model result

        GroupsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        GroupsInit (Err _) ->
            ( model, Cmd.none )

        GroupInit (Ok result) ->
            perform Page.Group.setup Group GroupMsg model result

        GroupInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        GroupInit (Err _) ->
            ( model, Cmd.none )

        NewGroupInit (Ok result) ->
            perform Page.NewGroup.setup NewGroup NewGroupMsg model result

        NewGroupInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        NewGroupInit (Err _) ->
            ( model, Cmd.none )

        GroupSettingsInit (Ok result) ->
            perform Page.GroupSettings.setup GroupSettings GroupSettingsMsg model result

        GroupSettingsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        GroupSettingsInit (Err _) ->
            ( model, Cmd.none )

        PostInit _ (Ok result) ->
            let
                ( newGlobals, pageModel ) =
                    result
            in
            perform (Page.Post.setup newGlobals) Post PostMsg model result

        PostInit _ (Err Session.Expired) ->
            ( model, Route.toLogin )

        PostInit _ (Err _) ->
            ( model, Cmd.none )

        UserSettingsInit (Ok result) ->
            perform Page.UserSettings.setup UserSettings UserSettingsMsg model result

        UserSettingsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        UserSettingsInit (Err _) ->
            ( model, Cmd.none )

        SpaceSettingsInit (Ok result) ->
            perform Page.Settings.setup SpaceSettings SpaceSettingsMsg model result

        SpaceSettingsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SpaceSettingsInit (Err _) ->
            ( model, Cmd.none )

        SearchInit (Ok result) ->
            perform Page.Search.setup Search SearchMsg model result

        SearchInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SearchInit (Err err) ->
            ( model, Cmd.none )

        WelcomeTutorialInit (Ok result) ->
            let
                ( newGlobals, pageModel ) =
                    result
            in
            perform (Page.WelcomeTutorial.setup newGlobals) WelcomeTutorial WelcomeTutorialMsg model result

        WelcomeTutorialInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        WelcomeTutorialInit (Err err) ->
            ( model, Cmd.none )

        HelpInit (Ok result) ->
            perform Page.Help.setup Help HelpMsg model result

        HelpInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        HelpInit (Err err) ->
            ( model, Cmd.none )


teardownPage : Page -> Cmd Msg
teardownPage page =
    case page of
        Spaces pageModel ->
            Cmd.map SpacesMsg (Page.Spaces.teardown pageModel)

        NewSpace pageModel ->
            Cmd.map NewSpaceMsg (Page.NewSpace.teardown pageModel)

        SpaceUser pageModel ->
            Cmd.map SpaceUserMsg (Page.SpaceUser.teardown pageModel)

        SpaceUsers pageModel ->
            Cmd.map SpaceUsersMsg (Page.SpaceUsers.teardown pageModel)

        InviteUsers pageModel ->
            Cmd.map InviteUsersMsg (Page.InviteUsers.teardown pageModel)

        Group pageModel ->
            Cmd.map GroupMsg (Page.Group.teardown pageModel)

        GroupSettings pageModel ->
            Cmd.map GroupSettingsMsg (Page.GroupSettings.teardown pageModel)

        UserSettings pageModel ->
            Cmd.map UserSettingsMsg (Page.UserSettings.teardown pageModel)

        SpaceSettings pageModel ->
            Cmd.map SpaceSettingsMsg (Page.Settings.teardown pageModel)

        Posts pageModel ->
            Cmd.map PostsMsg (Page.Posts.teardown pageModel)

        Post pageModel ->
            Cmd.map PostMsg (Page.Post.teardown pageModel)

        Search pageModel ->
            Cmd.map SearchMsg (Page.Search.teardown pageModel)

        WelcomeTutorial pageModel ->
            Cmd.map WelcomeTutorialMsg (Page.WelcomeTutorial.teardown pageModel)

        Help pageModel ->
            Cmd.map HelpMsg (Page.Help.teardown pageModel)

        _ ->
            Cmd.none


pageSubscription : Page -> Sub Msg
pageSubscription page =
    case page of
        Spaces _ ->
            Sub.map SpacesMsg Page.Spaces.subscriptions

        NewSpace _ ->
            Sub.map NewSpaceMsg Page.NewSpace.subscriptions

        Posts _ ->
            Sub.map PostsMsg Page.Posts.subscriptions

        Inbox _ ->
            Sub.map InboxMsg Page.Inbox.subscriptions

        Group _ ->
            Sub.map GroupMsg Page.Group.subscriptions

        Post _ ->
            Sub.map PostMsg Page.Post.subscriptions

        UserSettings _ ->
            Sub.map UserSettingsMsg Page.UserSettings.subscriptions

        SpaceSettings _ ->
            Sub.map SpaceSettingsMsg Page.Settings.subscriptions

        Search _ ->
            Sub.map SearchMsg Page.Search.subscriptions

        _ ->
            Sub.none


routeFor : Page -> Maybe Route
routeFor page =
    case page of
        Spaces _ ->
            Just Route.Spaces

        NewSpace _ ->
            Just Route.NewSpace

        Posts { params } ->
            Just <| Route.Posts params

        Inbox { params } ->
            Just <| Route.Inbox params

        SpaceUser { params } ->
            Just <| Route.SpaceUser params

        SpaceUsers { params } ->
            Just <| Route.SpaceUsers params

        InviteUsers { spaceSlug } ->
            Just <| Route.InviteUsers spaceSlug

        Groups { params } ->
            Just <| Route.Groups params

        Group { params } ->
            Just <| Route.Group params

        NewGroup { spaceSlug } ->
            Just <| Route.NewGroup spaceSlug

        GroupSettings { params } ->
            Just <| Route.GroupSettings params

        Post { spaceSlug, postComp } ->
            Just <| Route.Post spaceSlug postComp.id

        UserSettings _ ->
            Just <| Route.UserSettings

        SpaceSettings { params } ->
            Just <| Route.Settings params

        Search { params } ->
            Just <| Route.Search params

        WelcomeTutorial { params } ->
            Just <| Route.WelcomeTutorial params

        Help { params } ->
            Just <| Route.Help params

        Blank ->
            Nothing

        NotFound ->
            Nothing


pageView : Globals -> Page -> Html Msg
pageView globals page =
    case page of
        Spaces pageModel ->
            pageModel
                |> Page.Spaces.view globals
                |> Html.map SpacesMsg

        NewSpace pageModel ->
            pageModel
                |> Page.NewSpace.view globals
                |> Html.map NewSpaceMsg

        Posts pageModel ->
            pageModel
                |> Page.Posts.view globals
                |> Html.map PostsMsg

        Inbox pageModel ->
            pageModel
                |> Page.Inbox.view globals
                |> Html.map InboxMsg

        SpaceUser pageModel ->
            pageModel
                |> Page.SpaceUser.view globals.repo (routeFor page)
                |> Html.map SpaceUserMsg

        SpaceUsers pageModel ->
            pageModel
                |> Page.SpaceUsers.view globals.repo (routeFor page)
                |> Html.map SpaceUsersMsg

        InviteUsers pageModel ->
            pageModel
                |> Page.InviteUsers.view globals.repo (routeFor page)
                |> Html.map InviteUsersMsg

        Groups pageModel ->
            pageModel
                |> Page.Groups.view globals.repo (routeFor page)
                |> Html.map GroupsMsg

        Group pageModel ->
            pageModel
                |> Page.Group.view globals.repo (routeFor page) globals.spaceUserLists
                |> Html.map GroupMsg

        NewGroup pageModel ->
            pageModel
                |> Page.NewGroup.view globals.repo (routeFor page)
                |> Html.map NewGroupMsg

        GroupSettings pageModel ->
            pageModel
                |> Page.GroupSettings.view globals.repo (routeFor page)
                |> Html.map GroupSettingsMsg

        Post pageModel ->
            pageModel
                |> Page.Post.view globals.repo (routeFor page) globals.spaceUserLists
                |> Html.map PostMsg

        UserSettings pageModel ->
            pageModel
                |> Page.UserSettings.view globals
                |> Html.map UserSettingsMsg

        SpaceSettings pageModel ->
            pageModel
                |> Page.Settings.view globals.repo (routeFor page)
                |> Html.map SpaceSettingsMsg

        Search pageModel ->
            pageModel
                |> Page.Search.view globals.repo (routeFor page)
                |> Html.map SearchMsg

        WelcomeTutorial pageModel ->
            pageModel
                |> Page.WelcomeTutorial.view globals.repo (routeFor page)
                |> Html.map WelcomeTutorialMsg

        Help pageModel ->
            pageModel
                |> Page.Help.view globals.repo (routeFor page)
                |> Html.map HelpMsg

        Blank ->
            div [ class "font-sans font-antialised flex items-center justify-center h-screen w-full bg-turquoise" ]
                [ h1 [ class "text-3xl tracking-semi-tight text-white font-black" ] [ text "Loading..." ]
                ]

        NotFound ->
            div [ class "font-sans font-antialised justify-center h-screen w-full text-center pt-24" ]
                [ h1 [ class "mb-1 text-6xl tracking-semi-tight text-dusty-blue-darker font-black" ] [ text "404" ]
                , h2 [ class "text-2xl text-dusty-blue-darker font-normal" ] [ text "Page not found" ]
                ]



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event ({ page } as model) =
    case event of
        Event.GroupBookmarked group ->
            ( { model | repo = Repo.setGroup group model.repo }
            , Cmd.none
            )

        Event.GroupUnbookmarked group ->
            ( { model | repo = Repo.setGroup group model.repo }
            , Cmd.none
            )

        Event.SubscribedToGroup group ->
            ( { model | repo = Repo.setGroup group model.repo }
            , Cmd.none
            )

        Event.UnsubscribedFromGroup group ->
            ( { model | repo = Repo.setGroup group model.repo }
            , Cmd.none
            )

        Event.PostCreated ( post, replies ) ->
            let
                repo =
                    model.repo
                        |> Repo.setPost post
                        |> Repo.setReplies (Connection.toList replies)
            in
            ( { model | repo = repo }
            , Cmd.none
            )

        Event.PostUpdated post ->
            ( { model | repo = Repo.setPost post model.repo }
            , Cmd.none
            )

        Event.PostReactionCreated post ->
            ( { model | repo = Repo.setPost post model.repo }
            , Cmd.none
            )

        Event.PostReactionDeleted post ->
            ( { model | repo = Repo.setPost post model.repo }
            , Cmd.none
            )

        Event.ReplyReactionCreated reply ->
            ( { model | repo = Repo.setReply reply model.repo }
            , Cmd.none
            )

        Event.ReplyReactionDeleted reply ->
            ( { model | repo = Repo.setReply reply model.repo }
            , Cmd.none
            )

        Event.PostsSubscribed posts ->
            ( { model | repo = Repo.setPosts posts model.repo }
            , Cmd.none
            )

        Event.PostsUnsubscribed posts ->
            ( { model | repo = Repo.setPosts posts model.repo }
            , Cmd.none
            )

        Event.PostsMarkedAsUnread posts ->
            ( { model | repo = Repo.setPosts posts model.repo }
            , Cmd.none
            )

        Event.PostsMarkedAsRead posts ->
            ( { model | repo = Repo.setPosts posts model.repo }
            , Cmd.none
            )

        Event.PostsDismissed posts ->
            ( { model | repo = Repo.setPosts posts model.repo }
            , Cmd.none
            )

        Event.UserMentioned post ->
            ( { model | repo = Repo.setPost post model.repo }
            , Cmd.none
            )

        Event.GroupUpdated group ->
            ( { model | repo = Repo.setGroup group model.repo }
            , Cmd.none
            )

        Event.ReplyCreated reply ->
            ( { model | repo = Repo.setReply reply model.repo }
            , Cmd.none
            )

        Event.ReplyUpdated reply ->
            ( { model | repo = Repo.setReply reply model.repo }
            , Cmd.none
            )

        Event.MentionsDismissed post ->
            ( { model | repo = Repo.setPost post model.repo }
            , Cmd.none
            )

        Event.RepliesViewed replies ->
            ( { model | repo = Repo.setReplies replies model.repo }
            , Cmd.none
            )

        Event.SpaceUpdated space ->
            ( { model | repo = Repo.setSpace space model.repo }
            , Cmd.none
            )

        Event.SpaceUserUpdated spaceUser ->
            ( { model | repo = Repo.setSpaceUser spaceUser model.repo }
            , Cmd.none
            )

        Event.PostClosed post ->
            ( { model | repo = Repo.setPost post model.repo }
            , Cmd.none
            )

        Event.PostReopened post ->
            ( { model | repo = Repo.setPost post model.repo }
            , Cmd.none
            )

        Event.Unknown payload ->
            ( model, Cmd.none )


sendEventToPage : Globals -> Event -> Model -> ( Model, Cmd Msg )
sendEventToPage globals event model =
    case model.page of
        Spaces pageModel ->
            pageModel
                |> Page.Spaces.consumeEvent event
                |> updatePage Spaces SpacesMsg model

        NewSpace pageModel ->
            pageModel
                |> Page.NewSpace.consumeEvent event
                |> updatePage NewSpace NewSpaceMsg model

        Posts pageModel ->
            pageModel
                |> Page.Posts.consumeEvent event
                |> updatePage Posts PostsMsg model

        Inbox pageModel ->
            pageModel
                |> Page.Inbox.consumeEvent event globals
                |> updatePage Inbox InboxMsg model

        SpaceUser pageModel ->
            pageModel
                |> Page.SpaceUser.consumeEvent event
                |> updatePage SpaceUser SpaceUserMsg model

        SpaceUsers pageModel ->
            pageModel
                |> Page.SpaceUsers.consumeEvent event
                |> updatePage SpaceUsers SpaceUsersMsg model

        InviteUsers pageModel ->
            pageModel
                |> Page.InviteUsers.consumeEvent event
                |> updatePage InviteUsers InviteUsersMsg model

        Groups pageModel ->
            pageModel
                |> Page.Groups.consumeEvent event
                |> updatePage Groups GroupsMsg model

        Group pageModel ->
            pageModel
                |> Page.Group.consumeEvent event model.session
                |> updatePage Group GroupMsg model

        NewGroup pageModel ->
            pageModel
                |> Page.NewGroup.consumeEvent event
                |> updatePage NewGroup NewGroupMsg model

        GroupSettings pageModel ->
            pageModel
                |> Page.GroupSettings.consumeEvent event
                |> updatePage GroupSettings GroupSettingsMsg model

        Post pageModel ->
            pageModel
                |> Page.Post.consumeEvent globals event
                |> updatePage Post PostMsg model

        UserSettings pageModel ->
            pageModel
                |> Page.UserSettings.consumeEvent event
                |> updatePage UserSettings UserSettingsMsg model

        SpaceSettings pageModel ->
            pageModel
                |> Page.Settings.consumeEvent event
                |> updatePage SpaceSettings SpaceSettingsMsg model

        Search pageModel ->
            pageModel
                |> Page.Search.consumeEvent event
                |> updatePage Search SearchMsg model

        WelcomeTutorial pageModel ->
            pageModel
                |> Page.WelcomeTutorial.consumeEvent event
                |> updatePage WelcomeTutorial WelcomeTutorialMsg model

        Help pageModel ->
            pageModel
                |> Page.Help.consumeEvent event
                |> updatePage Help HelpMsg model

        Blank ->
            ( model, Cmd.none )

        NotFound ->
            ( model, Cmd.none )


sendPresenceToPage : Presence.Event -> Model -> ( Model, Cmd Msg )
sendPresenceToPage event model =
    case model.page of
        Post pageModel ->
            pageModel
                |> Page.Post.receivePresence event (buildGlobals model)
                |> updatePage Post PostMsg model

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Socket.receive SocketIn
        , PushManager.receive PushManagerIn
        , Presence.receive PresenceIn
        , pageSubscription model.page
        ]



-- VIEW


view : Model -> Document Msg
view model =
    Document (pageTitle model.repo model.page)
        [ pageView (buildGlobals model) model.page
        , centerNoticeView model
        ]


centerNoticeView : Model -> Html Msg
centerNoticeView model =
    viewIf (model.socketState == SocketState.Closed) <|
        div [ class "font-sans font-antialised fixed px-3 pin-t pin-l-50 z-50", style "transform" "translateX(-50%)" ]
            [ div [ class "relative px-5 py-4 border-b-3 border-red bg-red-lightest text-sm text-red" ]
                [ h2 [ class "pb-2 font-extrabold text-lg" ] [ text "Attempting to reconnect..." ]
                , p [ class "text-sm" ] [ text "If the problem persists, try refreshing the page." ]
                ]
            ]
