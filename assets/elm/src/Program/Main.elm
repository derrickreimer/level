module Program.Main exposing (main)

import Avatar exposing (personAvatar, thingAvatar)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Connection
import Event exposing (Event)
import Globals exposing (Globals)
import Html exposing (..)
import Html.Attributes exposing (..)
import Id exposing (Id)
import Json.Decode as Decode exposing (decodeString)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.RegisterPushSubscription as RegisterPushSubscription
import Page.Group
import Page.GroupPermissions
import Page.Groups
import Page.Inbox
import Page.InviteUsers
import Page.NewGroup
import Page.NewSpace
import Page.Post
import Page.Posts
import Page.Search
import Page.Setup.CreateGroups
import Page.Setup.InviteUsers
import Page.SpaceSettings
import Page.SpaceUsers
import Page.Spaces
import Page.UserSettings
import Presence exposing (PresenceList)
import PushManager
import PushStatus exposing (PushStatus)
import Query.GetSpaceUserLists as GetSpaceUserLists
import Query.MainInit as MainInit
import Repo exposing (Repo)
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
import Util exposing (Lazy(..))
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
    , repo : Repo
    , page : Page
    , isTransitioning : Bool
    , pushStatus : PushStatus
    , socketState : SocketState
    , spaceUserLists : SpaceUserLists
    }


type alias Flags =
    { apiToken : String
    , supportsNotifications : Bool
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
        Repo.empty
        Blank
        True
        (PushStatus.init flags.supportsNotifications)
        SocketState.Unknown
        SpaceUserLists.init


setup : MainInit.Response -> Model -> Cmd Msg
setup { spaceIds, spaceUserIds } model =
    let
        spaceSubs =
            List.map SpaceSubscription.subscribe spaceIds

        spaceUserSubs =
            List.map SpaceUserSubscription.subscribe spaceUserIds

        getSpaceUserLists =
            model.session
                |> GetSpaceUserLists.request
                |> Task.attempt SpaceUserListsLoaded
    in
    Cmd.batch (spaceSubs ++ spaceUserSubs ++ [ getSpaceUserLists ])



-- UPDATE


type Msg
    = UrlChange Url
    | UrlRequest UrlRequest
    | AppInitialized (Result Session.Error ( Session, MainInit.Response ))
    | SessionRefreshed (Result Session.Error Session)
    | SpaceUserListsLoaded (Result Session.Error ( Session, GetSpaceUserLists.Response ))
    | PageInitialized PageInit
    | SetupCreateGroupsMsg Page.Setup.CreateGroups.Msg
    | SetupInviteUsersMsg Page.Setup.InviteUsers.Msg
    | SpacesMsg Page.Spaces.Msg
    | NewSpaceMsg Page.NewSpace.Msg
    | PostsMsg Page.Posts.Msg
    | InboxMsg Page.Inbox.Msg
    | SpaceUsersMsg Page.SpaceUsers.Msg
    | InviteUsersMsg Page.InviteUsers.Msg
    | GroupsMsg Page.Groups.Msg
    | GroupMsg Page.Group.Msg
    | NewGroupMsg Page.NewGroup.Msg
    | GroupPermissionsMsg Page.GroupPermissions.Msg
    | PostMsg Page.Post.Msg
    | UserSettingsMsg Page.UserSettings.Msg
    | SpaceSettingsMsg Page.SpaceSettings.Msg
    | SearchMsg Page.Search.Msg
    | SocketIn Decode.Value
    | PushManagerIn Decode.Value
    | PushSubscriptionRegistered (Result Session.Error ( Session, RegisterPushSubscription.Response ))
    | PresenceIn Decode.Value


updatePage : (a -> Page) -> (b -> Msg) -> Model -> ( a, Cmd b ) -> ( Model, Cmd Msg )
updatePage toPage toPageMsg model ( pageModel, pageCmd ) =
    ( { model | page = toPage pageModel }
    , Cmd.map toPageMsg pageCmd
    )


updatePageWithGlobals : (a -> Page) -> (b -> Msg) -> Model -> ( ( a, Cmd b ), Globals ) -> ( Model, Cmd Msg )
updatePageWithGlobals toPage toPageMsg model ( ( newPageModel, pageCmd ), newGlobals ) =
    ( { model
        | session = newGlobals.session
        , repo = newGlobals.repo
        , page = toPage newPageModel
      }
    , Cmd.map toPageMsg pageCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        globals =
            Globals model.session model.repo model.navKey
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
            ( { model | session = newSession }
            , setup response model
            )

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

        ( SetupCreateGroupsMsg pageMsg, SetupCreateGroups pageModel ) ->
            let
                ( ( newPageModel, pageCmd ), newGlobals, externalMsg ) =
                    Page.Setup.CreateGroups.update pageMsg globals pageModel

                ( newModel, cmd ) =
                    case externalMsg of
                        Page.Setup.CreateGroups.SetupStateChanged newState ->
                            ( model
                            , Route.pushUrl model.navKey (Space.setupRoute pageModel.spaceSlug newState)
                            )

                        Page.Setup.CreateGroups.NoOp ->
                            ( model, Cmd.none )
            in
            ( { newModel
                | session = newGlobals.session
                , repo = newGlobals.repo
                , page = SetupCreateGroups newPageModel
              }
            , Cmd.batch
                [ Cmd.map SetupCreateGroupsMsg pageCmd
                , cmd
                ]
            )

        ( SetupInviteUsersMsg pageMsg, SetupInviteUsers pageModel ) ->
            let
                ( ( newPageModel, pageCmd ), newGlobals, externalMsg ) =
                    Page.Setup.InviteUsers.update pageMsg globals pageModel

                ( newModel, cmd ) =
                    case externalMsg of
                        Page.Setup.InviteUsers.SetupStateChanged newState ->
                            ( model
                            , Route.pushUrl model.navKey (Space.setupRoute pageModel.spaceSlug newState)
                            )

                        Page.Setup.InviteUsers.NoOp ->
                            ( model, Cmd.none )
            in
            ( { newModel
                | session = newGlobals.session
                , repo = newGlobals.repo
                , page = SetupInviteUsers newPageModel
              }
            , Cmd.batch
                [ Cmd.map SetupInviteUsersMsg pageCmd
                , cmd
                ]
            )

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

        ( GroupPermissionsMsg pageMsg, GroupPermissions pageModel ) ->
            pageModel
                |> Page.GroupPermissions.update pageMsg globals
                |> updatePageWithGlobals GroupPermissions GroupPermissionsMsg model

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
                |> Page.SpaceSettings.update pageMsg globals
                |> updatePageWithGlobals SpaceSettings SpaceSettingsMsg model

        ( SearchMsg pageMsg, Search pageModel ) ->
            pageModel
                |> Page.Search.update pageMsg globals
                |> updatePageWithGlobals Search SearchMsg model

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

        ( _, _ ) ->
            -- Disregard incoming messages that arrived for the wrong page
            ( model, Cmd.none )



-- PAGES


type Page
    = Blank
    | NotFound
    | Spaces Page.Spaces.Model
    | NewSpace Page.NewSpace.Model
    | SetupCreateGroups Page.Setup.CreateGroups.Model
    | SetupInviteUsers Page.Setup.InviteUsers.Model
    | Posts Page.Posts.Model
    | Inbox Page.Inbox.Model
    | SpaceUsers Page.SpaceUsers.Model
    | InviteUsers Page.InviteUsers.Model
    | Groups Page.Groups.Model
    | Group Page.Group.Model
    | NewGroup Page.NewGroup.Model
    | GroupPermissions Page.GroupPermissions.Model
    | Post Page.Post.Model
    | UserSettings Page.UserSettings.Model
    | SpaceSettings Page.SpaceSettings.Model
    | Search Page.Search.Model


type PageInit
    = SpacesInit (Result Session.Error ( Globals, Page.Spaces.Model ))
    | NewSpaceInit (Result Session.Error ( Globals, Page.NewSpace.Model ))
    | PostsInit (Result Session.Error ( Globals, Page.Posts.Model ))
    | InboxInit (Result Session.Error ( Globals, Page.Inbox.Model ))
    | SpaceUsersInit (Result Session.Error ( Globals, Page.SpaceUsers.Model ))
    | InviteUsersInit (Result Session.Error ( Globals, Page.InviteUsers.Model ))
    | GroupsInit (Result Session.Error ( Globals, Page.Groups.Model ))
    | GroupInit (Result Session.Error ( Globals, Page.Group.Model ))
    | NewGroupInit (Result Session.Error ( Globals, Page.NewGroup.Model ))
    | GroupPermissionsInit (Result Session.Error ( Globals, Page.GroupPermissions.Model ))
    | PostInit String (Result Session.Error ( Globals, Page.Post.Model ))
    | UserSettingsInit (Result Session.Error ( Globals, Page.UserSettings.Model ))
    | SpaceSettingsInit (Result Session.Error ( Globals, Page.SpaceSettings.Model ))
    | SetupCreateGroupsInit (Result Session.Error ( Globals, Page.Setup.CreateGroups.Model ))
    | SetupInviteUsersInit (Result Session.Error ( Globals, Page.Setup.InviteUsers.Model ))
    | SearchInit (Result Session.Error ( Globals, Page.Search.Model ))


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
            Globals model.session model.repo model.navKey
    in
    case maybeRoute of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just (Route.Root spaceSlug) ->
            navigateTo (Just <| Route.Inbox (Route.Inbox.init spaceSlug)) model

        Just (Route.SetupCreateGroups spaceSlug) ->
            globals
                |> Page.Setup.CreateGroups.init spaceSlug
                |> transition model SetupCreateGroupsInit

        Just (Route.SetupInviteUsers spaceSlug) ->
            globals
                |> Page.Setup.InviteUsers.init spaceSlug
                |> transition model SetupInviteUsersInit

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

        Just (Route.GroupPermissions params) ->
            globals
                |> Page.GroupPermissions.init params
                |> transition model GroupPermissionsInit

        Just (Route.Post spaceSlug postId) ->
            globals
                |> Page.Post.init spaceSlug postId
                |> transition model (PostInit postId)

        Just (Route.SpaceSettings spaceSlug) ->
            globals
                |> Page.SpaceSettings.init spaceSlug
                |> transition model SpaceSettingsInit

        Just Route.UserSettings ->
            globals
                |> Page.UserSettings.init
                |> transition model UserSettingsInit

        Just (Route.Search params) ->
            globals
                |> Page.Search.init params
                |> transition model SearchInit


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

        SpaceUsers _ ->
            Page.SpaceUsers.title

        Group pageModel ->
            Page.Group.title repo pageModel

        Groups _ ->
            Page.Groups.title

        NewGroup _ ->
            Page.NewGroup.title

        GroupPermissions _ ->
            Page.GroupPermissions.title

        Post pageModel ->
            Page.Post.title pageModel

        SpaceSettings _ ->
            Page.SpaceSettings.title

        InviteUsers _ ->
            Page.InviteUsers.title

        UserSettings _ ->
            Page.UserSettings.title

        SetupCreateGroups _ ->
            Page.Setup.CreateGroups.title

        SetupInviteUsers _ ->
            Page.Setup.InviteUsers.title

        Search pageModel ->
            Page.Search.title pageModel

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

        InboxInit (Ok result) ->
            let
                ( newGlobals, pageModel ) =
                    result
            in
            perform (Page.Inbox.setup newGlobals) Inbox InboxMsg model result

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

        GroupPermissionsInit (Ok result) ->
            perform Page.GroupPermissions.setup GroupPermissions GroupPermissionsMsg model result

        GroupPermissionsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        GroupPermissionsInit (Err _) ->
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
            perform Page.SpaceSettings.setup SpaceSettings SpaceSettingsMsg model result

        SpaceSettingsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SpaceSettingsInit (Err _) ->
            ( model, Cmd.none )

        SetupCreateGroupsInit (Ok result) ->
            perform Page.Setup.CreateGroups.setup
                SetupCreateGroups
                SetupCreateGroupsMsg
                model
                result

        SetupCreateGroupsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SetupCreateGroupsInit (Err _) ->
            ( model, Cmd.none )

        SetupInviteUsersInit (Ok result) ->
            perform Page.Setup.InviteUsers.setup
                SetupInviteUsers
                SetupInviteUsersMsg
                model
                result

        SetupInviteUsersInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SetupInviteUsersInit (Err _) ->
            ( model, Cmd.none )

        SearchInit (Ok result) ->
            perform Page.Search.setup Search SearchMsg model result

        SearchInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        SearchInit (Err err) ->
            ( model, Cmd.none )


teardownPage : Page -> Cmd Msg
teardownPage page =
    case page of
        Spaces pageModel ->
            Cmd.map SpacesMsg (Page.Spaces.teardown pageModel)

        NewSpace pageModel ->
            Cmd.map NewSpaceMsg (Page.NewSpace.teardown pageModel)

        SpaceUsers pageModel ->
            Cmd.map SpaceUsersMsg (Page.SpaceUsers.teardown pageModel)

        InviteUsers pageModel ->
            Cmd.map InviteUsersMsg (Page.InviteUsers.teardown pageModel)

        Group pageModel ->
            Cmd.map GroupMsg (Page.Group.teardown pageModel)

        GroupPermissions pageModel ->
            Cmd.map GroupPermissionsMsg (Page.GroupPermissions.teardown pageModel)

        UserSettings pageModel ->
            Cmd.map UserSettingsMsg (Page.UserSettings.teardown pageModel)

        SpaceSettings pageModel ->
            Cmd.map SpaceSettingsMsg (Page.SpaceSettings.teardown pageModel)

        Posts pageModel ->
            Cmd.map PostsMsg (Page.Posts.teardown pageModel)

        Post pageModel ->
            Cmd.map PostMsg (Page.Post.teardown pageModel)

        Search pageModel ->
            Cmd.map SearchMsg (Page.Search.teardown pageModel)

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
            Sub.map SpaceSettingsMsg Page.SpaceSettings.subscriptions

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

        SetupCreateGroups { spaceSlug } ->
            Just <| Route.SetupCreateGroups spaceSlug

        SetupInviteUsers { spaceSlug } ->
            Just <| Route.SetupInviteUsers spaceSlug

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

        GroupPermissions { params } ->
            Just <| Route.GroupPermissions params

        Post { spaceSlug, postComp } ->
            Just <| Route.Post spaceSlug postComp.id

        UserSettings _ ->
            Just <| Route.UserSettings

        SpaceSettings { spaceSlug } ->
            Just <| Route.SpaceSettings spaceSlug

        Search { params } ->
            Just <| Route.Search params

        Blank ->
            Nothing

        NotFound ->
            Nothing


pageView : Repo -> Page -> PushStatus -> SpaceUserLists -> Html Msg
pageView repo page pushStatus spaceUserLists =
    case page of
        Spaces pageModel ->
            pageModel
                |> Page.Spaces.view repo
                |> Html.map SpacesMsg

        NewSpace pageModel ->
            pageModel
                |> Page.NewSpace.view repo
                |> Html.map NewSpaceMsg

        SetupCreateGroups pageModel ->
            pageModel
                |> Page.Setup.CreateGroups.view repo (routeFor page)
                |> Html.map SetupCreateGroupsMsg

        SetupInviteUsers pageModel ->
            pageModel
                |> Page.Setup.InviteUsers.view repo (routeFor page)
                |> Html.map SetupInviteUsersMsg

        Posts pageModel ->
            pageModel
                |> Page.Posts.view repo (routeFor page) spaceUserLists
                |> Html.map PostsMsg

        Inbox pageModel ->
            pageModel
                |> Page.Inbox.view repo (routeFor page) pushStatus spaceUserLists
                |> Html.map InboxMsg

        SpaceUsers pageModel ->
            pageModel
                |> Page.SpaceUsers.view repo (routeFor page)
                |> Html.map SpaceUsersMsg

        InviteUsers pageModel ->
            pageModel
                |> Page.InviteUsers.view repo (routeFor page)
                |> Html.map InviteUsersMsg

        Groups pageModel ->
            pageModel
                |> Page.Groups.view repo (routeFor page)
                |> Html.map GroupsMsg

        Group pageModel ->
            pageModel
                |> Page.Group.view repo (routeFor page) spaceUserLists
                |> Html.map GroupMsg

        NewGroup pageModel ->
            pageModel
                |> Page.NewGroup.view repo (routeFor page)
                |> Html.map NewGroupMsg

        GroupPermissions pageModel ->
            pageModel
                |> Page.GroupPermissions.view repo (routeFor page)
                |> Html.map GroupPermissionsMsg

        Post pageModel ->
            pageModel
                |> Page.Post.view repo (routeFor page) spaceUserLists
                |> Html.map PostMsg

        UserSettings pageModel ->
            pageModel
                |> Page.UserSettings.view repo
                |> Html.map UserSettingsMsg

        SpaceSettings pageModel ->
            pageModel
                |> Page.SpaceSettings.view repo (routeFor page)
                |> Html.map SpaceSettingsMsg

        Search pageModel ->
            pageModel
                |> Page.Search.view repo (routeFor page)
                |> Html.map SearchMsg

        Blank ->
            div [ class "font-sans font-antialised flex items-center justify-center h-screen w-full bg-turquoise" ]
                [ h1 [ class "text-3xl text-white font-black" ] [ text "Loading..." ]
                ]

        NotFound ->
            text "404"



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

        SetupCreateGroups pageModel ->
            pageModel
                |> Page.Setup.CreateGroups.consumeEvent event
                |> updatePage SetupCreateGroups SetupCreateGroupsMsg model

        SetupInviteUsers pageModel ->
            pageModel
                |> Page.Setup.InviteUsers.consumeEvent event
                |> updatePage SetupInviteUsers SetupInviteUsersMsg model

        Posts pageModel ->
            pageModel
                |> Page.Posts.consumeEvent event
                |> updatePage Posts PostsMsg model

        Inbox pageModel ->
            pageModel
                |> Page.Inbox.consumeEvent event globals
                |> updatePage Inbox InboxMsg model

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

        GroupPermissions pageModel ->
            pageModel
                |> Page.GroupPermissions.consumeEvent event
                |> updatePage GroupPermissions GroupPermissionsMsg model

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
                |> Page.SpaceSettings.consumeEvent event
                |> updatePage SpaceSettings SpaceSettingsMsg model

        Search pageModel ->
            pageModel
                |> Page.Search.consumeEvent event
                |> updatePage Search SearchMsg model

        Blank ->
            ( model, Cmd.none )

        NotFound ->
            ( model, Cmd.none )


sendPresenceToPage : Presence.Event -> Model -> ( Model, Cmd Msg )
sendPresenceToPage event model =
    case model.page of
        Post pageModel ->
            pageModel
                |> Page.Post.receivePresence event (Globals model.session model.repo model.navKey)
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
        [ pageView model.repo model.page model.pushStatus model.spaceUserLists
        , centerNoticeView model
        ]


centerNoticeView : Model -> Html Msg
centerNoticeView model =
    div [ class "font-sans font-antialised fixed px-3 pin-t pin-l-50 z-50", style "transform" "translateX(-50%)" ]
        [ viewIf (model.socketState == SocketState.Closed) <|
            div [ class "relative px-5 py-4 border-b-3 border-red bg-red-lightest text-sm text-red" ]
                [ h2 [ class "pb-2 font-extrabold text-lg" ] [ text "Attempting to reconnect..." ]
                , p [ class "text-sm" ] [ text "If the problem persists, try refreshing the page." ]
                ]
        ]
