module Program.Main exposing (main)

import Avatar exposing (personAvatar, thingAvatar)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Connection
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (decodeString)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.RegisterPushSubscription as RegisterPushSubscription
import NewRepo exposing (NewRepo)
import Page.Group
import Page.Groups
import Page.Inbox
import Page.NewGroup
import Page.NewSpace
import Page.Post
import Page.Posts
import Page.Setup.CreateGroups
import Page.Setup.InviteUsers
import Page.SpaceSettings
import Page.SpaceUsers
import Page.Spaces
import Page.UserSettings
import Post
import Presence exposing (PresenceList)
import PushManager
import Query.GetSpaceUser as GetSpaceUser
import Query.MainInit as MainInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Groups
import Route.Inbox
import Session exposing (Session)
import Socket
import Space exposing (Space)
import SpaceUser
import Subscription.SpaceSubscription as SpaceSubscription
import Subscription.SpaceUserSubscription as SpaceUserSubscription
import Task exposing (Task)
import Url exposing (Url)
import Util exposing (Lazy(..))
import View.Helpers exposing (displayName)
import View.Layout exposing (appLayout, spaceLayout)



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
    , newRepo : NewRepo
    , page : Page
    , isTransitioning : Bool
    , supportsNotifications : Bool
    , hasPushSubscription : Bool
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
        Repo.init
        NewRepo.empty
        Blank
        True
        flags.supportsNotifications
        False


setup : MainInit.Response -> Model -> Cmd Msg
setup { spaceIds, spaceUserIds } model =
    let
        spaceSubs =
            spaceIds
                |> List.map SpaceSubscription.subscribe

        spaceUserSubs =
            spaceUserIds
                |> List.map SpaceUserSubscription.subscribe
    in
    Cmd.batch (spaceSubs ++ spaceUserSubs)



-- UPDATE


type Msg
    = UrlChange Url
    | UrlRequest UrlRequest
    | AppInitialized (Result Session.Error ( Session, MainInit.Response ))
    | SessionRefreshed (Result Session.Error Session)
    | PageInitialized PageInit
    | SetupCreateGroupsMsg Page.Setup.CreateGroups.Msg
    | SetupInviteUsersMsg Page.Setup.InviteUsers.Msg
    | SpacesMsg Page.Spaces.Msg
    | NewSpaceMsg Page.NewSpace.Msg
    | PostsMsg Page.Posts.Msg
    | InboxMsg Page.Inbox.Msg
    | SpaceUsersMsg Page.SpaceUsers.Msg
    | GroupsMsg Page.Groups.Msg
    | GroupMsg Page.Group.Msg
    | NewGroupMsg Page.NewGroup.Msg
    | PostMsg Page.Post.Msg
    | UserSettingsMsg Page.UserSettings.Msg
    | SpaceSettingsMsg Page.SpaceSettings.Msg
    | SocketAbort Decode.Value
    | SocketStart Decode.Value
    | SocketResult Decode.Value
    | SocketError Decode.Value
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
        , newRepo = newGlobals.newRepo
        , page = toPage newPageModel
      }
    , Cmd.map toPageMsg pageCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        globals =
            Globals model.session model.repo model.newRepo
    in
    case ( msg, model.page ) of
        ( UrlChange url, _ ) ->
            navigateTo (Route.fromUrl url) model

        ( UrlRequest request, _ ) ->
            case request of
                Browser.Internal url ->
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
                , newRepo = newGlobals.newRepo
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
                , newRepo = newGlobals.newRepo
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

        ( SocketAbort value, _ ) ->
            ( model, Cmd.none )

        ( SocketStart value, _ ) ->
            ( model, Cmd.none )

        ( SocketResult value, page ) ->
            let
                event =
                    Event.decodeEvent value

                ( newModel, cmd ) =
                    consumeEvent event model

                ( newModel2, cmd2 ) =
                    sendEventToPage event newModel
            in
            ( newModel2, Cmd.batch [ cmd, cmd2 ] )

        ( SocketError value, _ ) ->
            let
                cmd =
                    model.session
                        |> Session.fetchNewToken
                        |> Task.attempt SessionRefreshed
            in
            ( model, cmd )

        ( PushManagerIn value, _ ) ->
            case PushManager.decodePayload value of
                PushManager.Subscription (Just data) ->
                    let
                        cmd =
                            model.session
                                |> RegisterPushSubscription.request data
                                |> Task.attempt PushSubscriptionRegistered
                    in
                    ( { model | hasPushSubscription = True }, cmd )

                PushManager.Subscription Nothing ->
                    ( { model | hasPushSubscription = False }, Cmd.none )

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
    | Groups Page.Groups.Model
    | Group Page.Group.Model
    | NewGroup Page.NewGroup.Model
    | Post Page.Post.Model
    | UserSettings Page.UserSettings.Model
    | SpaceSettings Page.SpaceSettings.Model


type PageInit
    = SpacesInit (Result Session.Error ( Globals, Page.Spaces.Model ))
    | NewSpaceInit (Result Session.Error ( Globals, Page.NewSpace.Model ))
    | PostsInit (Result Session.Error ( Globals, Page.Posts.Model ))
    | InboxInit (Result Session.Error ( Globals, Page.Inbox.Model ))
    | SpaceUsersInit (Result Session.Error ( Globals, Page.SpaceUsers.Model ))
    | GroupsInit (Result Session.Error ( Globals, Page.Groups.Model ))
    | GroupInit (Result Session.Error ( Globals, Page.Group.Model ))
    | NewGroupInit (Result Session.Error ( Globals, Page.NewGroup.Model ))
    | PostInit String (Result Session.Error ( Globals, Page.Post.Model ))
    | UserSettingsInit (Result Session.Error ( Globals, Page.UserSettings.Model ))
    | SpaceSettingsInit (Result Session.Error ( Globals, Page.SpaceSettings.Model ))
    | SetupCreateGroupsInit (Result Session.Error ( Globals, Page.Setup.CreateGroups.Model ))
    | SetupInviteUsersInit (Result Session.Error ( Globals, Page.Setup.InviteUsers.Model ))


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
            Globals model.session model.repo model.newRepo
    in
    case maybeRoute of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just (Route.Root spaceSlug) ->
            navigateTo (Just <| Route.Inbox (Route.Inbox.Root spaceSlug)) model

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


pageTitle : Repo -> NewRepo -> Page -> String
pageTitle repo newRepo page =
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
            Page.Group.title newRepo pageModel

        Groups _ ->
            Page.Groups.title

        NewGroup _ ->
            Page.NewGroup.title

        Post pageModel ->
            Page.Post.title pageModel

        SpaceSettings _ ->
            Page.SpaceSettings.title

        UserSettings _ ->
            Page.UserSettings.title

        SetupCreateGroups _ ->
            Page.Setup.CreateGroups.title

        SetupInviteUsers _ ->
            Page.Setup.InviteUsers.title

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
                , newRepo = newGlobals.newRepo
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
            perform Page.Inbox.setup Inbox InboxMsg model result

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


teardownPage : Page -> Cmd Msg
teardownPage page =
    case page of
        Spaces pageModel ->
            Cmd.map SpacesMsg (Page.Spaces.teardown pageModel)

        NewSpace pageModel ->
            Cmd.map NewSpaceMsg (Page.NewSpace.teardown pageModel)

        SpaceUsers pageModel ->
            Cmd.map SpaceUsersMsg (Page.SpaceUsers.teardown pageModel)

        Group pageModel ->
            Cmd.map GroupMsg (Page.Group.teardown pageModel)

        UserSettings pageModel ->
            Cmd.map UserSettingsMsg (Page.UserSettings.teardown pageModel)

        SpaceSettings pageModel ->
            Cmd.map SpaceSettingsMsg (Page.SpaceSettings.teardown pageModel)

        Posts pageModel ->
            Cmd.map PostsMsg (Page.Posts.teardown pageModel)

        Post pageModel ->
            Cmd.map PostMsg (Page.Post.teardown pageModel)

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

        Groups { params } ->
            Just <| Route.Groups params

        Group { params } ->
            Just <| Route.Group params

        NewGroup { spaceSlug } ->
            Just <| Route.NewGroup spaceSlug

        Post { spaceSlug, postComp } ->
            Just <| Route.Post spaceSlug postComp.id

        UserSettings _ ->
            Just <| Route.UserSettings

        SpaceSettings { spaceSlug } ->
            Just <| Route.SpaceSettings spaceSlug

        Blank ->
            Nothing

        NotFound ->
            Nothing


pageView : Repo -> NewRepo -> Page -> Bool -> Html Msg
pageView repo newRepo page hasPushSubscription =
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
                |> Page.Setup.CreateGroups.view newRepo (routeFor page)
                |> Html.map SetupCreateGroupsMsg

        SetupInviteUsers pageModel ->
            pageModel
                |> Page.Setup.InviteUsers.view newRepo (routeFor page)
                |> Html.map SetupInviteUsersMsg

        Posts pageModel ->
            pageModel
                |> Page.Posts.view newRepo (routeFor page)
                |> Html.map PostsMsg

        Inbox pageModel ->
            pageModel
                |> Page.Inbox.view newRepo (routeFor page) hasPushSubscription
                |> Html.map InboxMsg

        SpaceUsers pageModel ->
            pageModel
                |> Page.SpaceUsers.view repo (routeFor page)
                |> Html.map SpaceUsersMsg

        Groups pageModel ->
            pageModel
                |> Page.Groups.view newRepo (routeFor page)
                |> Html.map GroupsMsg

        Group pageModel ->
            pageModel
                |> Page.Group.view newRepo (routeFor page)
                |> Html.map GroupMsg

        NewGroup pageModel ->
            pageModel
                |> Page.NewGroup.view newRepo (routeFor page)
                |> Html.map NewGroupMsg

        Post pageModel ->
            pageModel
                |> Page.Post.view newRepo (routeFor page)
                |> Html.map PostMsg

        UserSettings pageModel ->
            pageModel
                |> Page.UserSettings.view newRepo
                |> Html.map UserSettingsMsg

        SpaceSettings pageModel ->
            pageModel
                |> Page.SpaceSettings.view newRepo (routeFor page)
                |> Html.map SpaceSettingsMsg

        Blank ->
            text ""

        NotFound ->
            text "404"



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event ({ page, repo, newRepo } as model) =
    case event of
        Event.GroupBookmarked group ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setGroup group
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.GroupUnbookmarked group ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setGroup group
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.GroupMembershipUpdated group ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setGroup group
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.PostCreated ( post, replies ) ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPost post
                        |> NewRepo.setReplies (Connection.toList replies)
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.PostUpdated post ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPost post
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.PostsSubscribed posts ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPosts posts
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.PostsUnsubscribed posts ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPosts posts
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.PostsMarkedAsUnread posts ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPosts posts
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.PostsMarkedAsRead posts ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPosts posts
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.PostsDismissed posts ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPosts posts
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.UserMentioned post ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPost post
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.GroupUpdated group ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setGroup group
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.ReplyCreated reply ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setReply reply
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.MentionsDismissed post ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setPost post
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.SpaceUpdated space ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setSpace space
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.SpaceUserUpdated spaceUser ->
            let
                newNewRepo =
                    model.newRepo
                        |> NewRepo.setSpaceUser spaceUser
            in
            ( { model | newRepo = newNewRepo }
            , Cmd.none
            )

        Event.Unknown payload ->
            ( model, Cmd.none )


sendEventToPage : Event -> Model -> ( Model, Cmd Msg )
sendEventToPage event model =
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
                |> Page.Inbox.consumeEvent event
                |> updatePage Inbox InboxMsg model

        SpaceUsers pageModel ->
            pageModel
                |> Page.SpaceUsers.consumeEvent event
                |> updatePage SpaceUsers SpaceUsersMsg model

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

        Post pageModel ->
            pageModel
                |> Page.Post.consumeEvent event
                |> updatePage Post PostMsg model

        UserSettings pageModel ->
            pageModel
                |> Page.UserSettings.consumeEvent event
                |> updatePage UserSettings UserSettingsMsg model

        SpaceSettings pageModel ->
            pageModel
                |> Page.SpaceSettings.consumeEvent event
                |> updatePage SpaceSettings SpaceSettingsMsg model

        Blank ->
            ( model, Cmd.none )

        NotFound ->
            ( model, Cmd.none )


sendPresenceToPage : Presence.Event -> Model -> ( Model, Cmd Msg )
sendPresenceToPage event model =
    case model.page of
        Post pageModel ->
            pageModel
                |> Page.Post.receivePresence event (Globals model.session model.repo model.newRepo)
                |> updatePage Post PostMsg model

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Socket.listen SocketAbort SocketStart SocketResult SocketError
        , PushManager.receive PushManagerIn
        , Presence.receive PresenceIn
        , pageSubscription model.page
        ]



-- VIEW


view : Model -> Document Msg
view model =
    Document (pageTitle model.repo model.newRepo model.page)
        [ pageView model.repo model.newRepo model.page model.hasPushSubscription
        ]
