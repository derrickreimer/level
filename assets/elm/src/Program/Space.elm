module Program.Space exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Navigation
import Task exposing (Task)
import Avatar exposing (personAvatar, thingAvatar)
import Data.Group as Group exposing (Group)
import Data.Post as Post
import Data.Space as Space
import Data.SpaceUser as SpaceUser
import Data.Setup as Setup
import Event
import Repo exposing (Repo)
import Page
import Page.Group
import Page.Groups
import Page.Inbox
import Page.NewGroup
import Page.Post
import Page.Setup.CreateGroups
import Page.Setup.InviteUsers
import Page.SpaceSettings
import Page.UserSettings
import Ports
import Query.SharedState
import Subscription.SpaceSubscription as SpaceSubscription
import Subscription.SpaceUserSubscription as SpaceUserSubscription
import Route exposing (Route)
import Session exposing (Session)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Util exposing (Lazy(..))
import ViewHelpers exposing (displayName)


-- MODEL


type alias Model =
    { spaceId : String
    , session : Session
    , sharedState : Lazy SharedState
    , page : Page
    , isTransitioning : Bool
    , flashNotice : Maybe String
    , repo : Repo
    }


type alias SharedState =
    Query.SharedState.Response


type alias Flags =
    { apiToken : String
    , spaceId : String
    }



-- LIFECYCLE


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        model =
            buildModel flags

        maybeRoute =
            Route.fromLocation location
    in
        ( model, bootstrap model.spaceId model.session maybeRoute )


buildModel : Flags -> Model
buildModel flags =
    Model flags.spaceId (Session.init flags.apiToken) NotLoaded Blank True Nothing Repo.init


bootstrap : String -> Session -> Maybe Route -> Cmd Msg
bootstrap spaceId session maybeRoute =
    session
        |> Query.SharedState.request spaceId
        |> Task.attempt (SharedStateLoaded maybeRoute)


setupSockets : SharedState -> Cmd Msg
setupSockets sharedState =
    Cmd.batch
        [ SpaceSubscription.subscribe (Space.getId sharedState.space)
        , SpaceUserSubscription.subscribe (SpaceUser.getId sharedState.user)
        ]



-- UPDATE


type Msg
    = UrlChanged Navigation.Location
    | SharedStateLoaded (Maybe Route) (Result Session.Error ( Session, Query.SharedState.Response ))
    | SessionRefreshed (Result Session.Error Session)
    | PageInitialized PageInit
    | SetupCreateGroupsMsg Page.Setup.CreateGroups.Msg
    | SetupInviteUsersMsg Page.Setup.InviteUsers.Msg
    | InboxMsg Page.Inbox.Msg
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
    | SocketTokenUpdated Decode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( UrlChanged location, _ ) ->
            case model.sharedState of
                Loaded sharedState ->
                    navigateTo (Route.fromLocation location) sharedState model

                _ ->
                    ( model, Cmd.none )

        ( SharedStateLoaded maybeRoute (Ok ( session, sharedState )), _ ) ->
            let
                ( newModel, navigateCmd ) =
                    navigateTo maybeRoute sharedState <|
                        { model | sharedState = Loaded sharedState, session = session }
            in
                ( newModel, Cmd.batch [ navigateCmd, setupSockets sharedState ] )

        ( SharedStateLoaded maybeRoute (Err Session.Expired), _ ) ->
            ( model, Route.toLogin )

        ( SharedStateLoaded maybeRoute (Err _), _ ) ->
            ( model, Cmd.none )

        ( SessionRefreshed (Ok session), _ ) ->
            ( { model | session = session }, Ports.updateToken session.token )

        ( SessionRefreshed (Err Session.Expired), _ ) ->
            ( model, Route.toLogin )

        ( PageInitialized pageInit, _ ) ->
            let
                ( newModel, cmd ) =
                    setupPage pageInit model
            in
                ( newModel
                , Cmd.batch
                    [ cmd
                    , Page.setTitle (pageTitle newModel.repo newModel.page)
                    ]
                )

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
                            case model.sharedState of
                                Loaded sharedState ->
                                    { model | sharedState = Loaded { sharedState | setupState = newState } }

                                NotLoaded ->
                                    model

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
                            case model.sharedState of
                                Loaded sharedState ->
                                    { model | sharedState = Loaded { sharedState | setupState = newState } }

                                NotLoaded ->
                                    model

                        Page.Setup.InviteUsers.NoOp ->
                            model
            in
                ( { newModel
                    | session = session
                    , page = SetupInviteUsers newPageModel
                  }
                , Cmd.map SetupInviteUsersMsg cmd
                )

        ( GroupMsg msg, Group pageModel ) ->
            let
                ( ( newPageModel, cmd ), session ) =
                    Page.Group.update msg model.repo model.session pageModel
            in
                ( { model | session = session, page = Group newPageModel }
                , Cmd.map GroupMsg cmd
                )

        ( NewGroupMsg msg, NewGroup pageModel ) ->
            let
                ( ( newPageModel, cmd ), session ) =
                    Page.NewGroup.update msg model.session pageModel
            in
                ( { model | session = session, page = NewGroup newPageModel }
                , Cmd.map NewGroupMsg cmd
                )

        ( PostMsg msg, Post pageModel ) ->
            let
                ( ( newPageModel, cmd ), session ) =
                    Page.Post.update msg model.repo model.session pageModel
            in
                ( { model | session = session, page = Post newPageModel }
                , Cmd.map PostMsg cmd
                )

        ( UserSettingsMsg msg, UserSettings pageModel ) ->
            let
                ( ( newPageModel, cmd ), session ) =
                    Page.UserSettings.update msg model.session pageModel
            in
                ( { model | session = session, page = UserSettings newPageModel }
                , Cmd.map UserSettingsMsg cmd
                )

        ( SpaceSettingsMsg msg, SpaceSettings pageModel ) ->
            let
                ( ( newPageModel, cmd ), session ) =
                    Page.SpaceSettings.update msg model.session pageModel
            in
                ( { model | session = session, page = SpaceSettings newPageModel }
                , Cmd.map SpaceSettingsMsg cmd
                )

        ( SocketAbort value, _ ) ->
            ( model, Cmd.none )

        ( SocketStart value, _ ) ->
            ( model, Cmd.none )

        ( SocketResult value, page ) ->
            case model.sharedState of
                Loaded sharedState ->
                    handleSocketResult value sharedState model

                NotLoaded ->
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

        ( _, _ ) ->
            -- Disregard incoming messages that arrived for the wrong page
            ( model, Cmd.none )



-- MUTATIONS


updateRepo : Repo -> Model -> ( Model, Cmd Msg )
updateRepo newRepo model =
    ( { model | repo = newRepo }, Cmd.none )



-- SOCKET EVENTS


handleSocketResult : Decode.Value -> SharedState -> Model -> ( Model, Cmd Msg )
handleSocketResult value sharedState ({ page, repo } as model) =
    case Event.decodeEvent value of
        Event.GroupBookmarked group ->
            let
                groups =
                    sharedState.bookmarkedGroups
                        |> insertUniqueBy (Group.getId) group

                newSharedState =
                    { sharedState | bookmarkedGroups = groups }

                newModel =
                    { model
                        | sharedState = Loaded newSharedState
                        , repo = Repo.setGroup model.repo group
                    }
            in
                ( newModel, Cmd.none )

        Event.GroupUnbookmarked group ->
            let
                groups =
                    sharedState.bookmarkedGroups
                        |> removeBy (Group.getId) group

                newSharedState =
                    { sharedState | bookmarkedGroups = groups }

                newModel =
                    { model
                        | sharedState = Loaded newSharedState
                        , repo = Repo.setGroup model.repo group
                    }
            in
                ( newModel, Cmd.none )

        Event.GroupMembershipUpdated group ->
            case model.page of
                Group pageModel ->
                    let
                        ( newPageModel, cmd ) =
                            Page.Group.handleGroupMembershipUpdated group model.session pageModel
                    in
                        ( { model
                            | page = Group newPageModel
                            , repo = Repo.setGroup model.repo group
                          }
                        , Cmd.map GroupMsg cmd
                        )

                _ ->
                    ( model, Cmd.none )

        Event.PostCreated post ->
            case model.page of
                Group ({ group } as pageModel) ->
                    if Post.groupsInclude group post then
                        let
                            ( newPageModel, cmd ) =
                                Page.Group.handlePostCreated post pageModel
                        in
                            ( { model | page = Group newPageModel }
                            , Cmd.map GroupMsg cmd
                            )
                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Event.GroupUpdated group ->
            updateRepo (Repo.setGroup repo group) model

        Event.ReplyCreated reply ->
            case page of
                Group pageModel ->
                    let
                        ( newPageModel, cmd ) =
                            Page.Group.handleReplyCreated reply pageModel
                    in
                        ( { model | page = Group newPageModel }
                        , Cmd.map GroupMsg cmd
                        )

                Post pageModel ->
                    let
                        ( newPageModel, cmd ) =
                            Page.Post.handleReplyCreated reply pageModel
                    in
                        ( { model | page = Post newPageModel }
                        , Cmd.map PostMsg cmd
                        )

                _ ->
                    ( model, Cmd.none )

        Event.SpaceUpdated space ->
            updateRepo (Repo.setSpace model.repo space) model

        Event.SpaceUserUpdated spaceUser ->
            updateRepo (Repo.setSpaceUser model.repo spaceUser) model

        Event.Unknown ->
            ( model, Cmd.none )



-- PAGES


type Page
    = Blank
    | NotFound
    | SetupCreateGroups Page.Setup.CreateGroups.Model
    | SetupInviteUsers Page.Setup.InviteUsers.Model
    | Inbox
    | Groups Page.Groups.Model
    | Group Page.Group.Model
    | NewGroup Page.NewGroup.Model
    | Post Page.Post.Model
    | UserSettings Page.UserSettings.Model
    | SpaceSettings Page.SpaceSettings.Model


type PageInit
    = GroupsInit (Result Session.Error ( Session, Page.Groups.Model ))
    | GroupInit String (Result Session.Error ( Session, Page.Group.Model ))
    | NewGroupInit (Result Never Page.NewGroup.Model)
    | PostInit String (Result Session.Error ( Session, Page.Post.Model ))
    | UserSettingsInit (Result Session.Error ( Session, Page.UserSettings.Model ))
    | SpaceSettingsInit (Result Never Page.SpaceSettings.Model)


navigateTo : Maybe Route -> SharedState -> Model -> ( Model, Cmd Msg )
navigateTo maybeRoute sharedState model =
    let
        { firstName, role } =
            Repo.getSpaceUser model.repo sharedState.user

        transition model toMsg task =
            ( { model | isTransitioning = True }
            , Cmd.batch
                [ teardownPage model.page
                , Cmd.map PageInitialized <| Task.attempt toMsg task
                ]
            )
    in
        case maybeRoute of
            Nothing ->
                ( { model | page = NotFound }, Cmd.none )

            Just Route.Root ->
                let
                    route =
                        case role of
                            SpaceUser.Owner ->
                                case sharedState.setupState of
                                    Setup.CreateGroups ->
                                        Just Route.SetupCreateGroups

                                    Setup.InviteUsers ->
                                        Just Route.SetupInviteUsers

                                    Setup.Complete ->
                                        Just Route.Inbox

                            _ ->
                                Just Route.Inbox
                in
                    navigateTo route sharedState model

            Just Route.SetupCreateGroups ->
                let
                    pageModel =
                        Page.Setup.CreateGroups.buildModel
                            (Space.getId sharedState.space)
                            firstName
                in
                    ( { model | page = SetupCreateGroups pageModel }
                    , Cmd.none
                    )

            Just Route.SetupInviteUsers ->
                let
                    pageModel =
                        Page.Setup.InviteUsers.buildModel
                            (Space.getId sharedState.space)
                            sharedState.openInvitationUrl
                in
                    ( { model | page = SetupInviteUsers pageModel }
                    , Cmd.none
                    )

            Just Route.Inbox ->
                -- TODO: implement this
                ( { model | page = Inbox }, Cmd.none )

            Just Route.Groups ->
                model.session
                    |> Page.Groups.init sharedState.user sharedState.space
                    |> transition model GroupsInit

            Just (Route.Group groupId) ->
                let
                    isBookmarked =
                        List.map Group.getId sharedState.bookmarkedGroups
                            |> List.member groupId
                in
                    model.session
                        |> Page.Group.init sharedState.user sharedState.space groupId
                        |> transition model (GroupInit groupId)

            Just Route.NewGroup ->
                sharedState.space
                    |> Page.NewGroup.init
                    |> transition model NewGroupInit

            Just (Route.Post postId) ->
                model.session
                    |> Page.Post.init sharedState.user sharedState.space postId
                    |> transition model (PostInit postId)

            Just Route.UserSettings ->
                model.session
                    |> Page.UserSettings.init
                    |> transition model UserSettingsInit

            Just Route.SpaceSettings ->
                sharedState.space
                    |> Page.SpaceSettings.init model.repo
                    |> transition model SpaceSettingsInit


setupPage : PageInit -> Model -> ( Model, Cmd Msg )
setupPage pageInit model =
    case pageInit of
        GroupsInit (Ok ( session, pageModel )) ->
            ( { model
                | page = Groups pageModel
                , session = session
                , isTransitioning = False
              }
            , Page.Groups.setup pageModel
                |> Cmd.map GroupsMsg
            )

        GroupsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        GroupsInit (Err _) ->
            -- TODO: Handle other error modes
            ( model, Cmd.none )

        GroupInit _ (Ok ( session, pageModel )) ->
            ( { model
                | page = Group pageModel
                , session = session
                , isTransitioning = False
              }
            , Page.Group.setup pageModel
                |> Cmd.map GroupMsg
            )

        GroupInit _ (Err Session.Expired) ->
            ( model, Route.toLogin )

        GroupInit _ (Err _) ->
            -- TODO: Handle other error modes
            ( model, Cmd.none )

        NewGroupInit (Ok pageModel) ->
            ( { model
                | page = NewGroup pageModel
                , isTransitioning = False
              }
            , Page.NewGroup.setup pageModel
                |> Cmd.map NewGroupMsg
            )

        NewGroupInit (Err _) ->
            -- TODO: Handle other error modes
            ( model, Cmd.none )

        PostInit _ (Ok ( session, pageModel )) ->
            ( { model
                | page = Post pageModel
                , session = session
                , isTransitioning = False
              }
            , Page.Post.setup pageModel
                |> Cmd.map PostMsg
            )

        PostInit _ (Err Session.Expired) ->
            ( model, Route.toLogin )

        PostInit _ (Err _) ->
            -- TODO: Handle other error modes
            ( model, Cmd.none )

        UserSettingsInit (Ok ( session, pageModel )) ->
            ( { model
                | page = UserSettings pageModel
                , session = session
                , isTransitioning = False
              }
            , Page.UserSettings.setup pageModel
                |> Cmd.map UserSettingsMsg
            )

        UserSettingsInit (Err Session.Expired) ->
            ( model, Route.toLogin )

        UserSettingsInit (Err _) ->
            -- TODO: Handle other error modes
            ( model, Cmd.none )

        SpaceSettingsInit (Ok pageModel) ->
            ( { model
                | page = SpaceSettings pageModel
                , isTransitioning = False
              }
            , Page.SpaceSettings.setup pageModel
                |> Cmd.map SpaceSettingsMsg
            )

        SpaceSettingsInit (Err _) ->
            -- TODO: Handle other error modes
            ( model, Cmd.none )


pageTitle : Repo -> Page -> String
pageTitle repo page =
    case page of
        Group pageModel ->
            Page.Group.title repo pageModel

        _ ->
            "Level"


teardownPage : Page -> Cmd Msg
teardownPage page =
    case page of
        Group pageModel ->
            Cmd.map GroupMsg (Page.Group.teardown pageModel)

        UserSettings pageModel ->
            Cmd.map UserSettingsMsg (Page.UserSettings.teardown pageModel)

        SpaceSettings pageModel ->
            Cmd.map SpaceSettingsMsg (Page.SpaceSettings.teardown pageModel)

        _ ->
            Cmd.none


routeFor : Page -> Maybe Route
routeFor page =
    case page of
        Inbox ->
            Just Route.Inbox

        SetupCreateGroups _ ->
            Just Route.SetupCreateGroups

        SetupInviteUsers _ ->
            Just Route.SetupInviteUsers

        Groups _ ->
            Just Route.Groups

        Group pageModel ->
            Just <| Route.Group (Group.getId pageModel.group)

        NewGroup _ ->
            Just Route.NewGroup

        Post pageModel ->
            Just <| Route.Post pageModel.post.id

        UserSettings _ ->
            Just Route.UserSettings

        SpaceSettings _ ->
            Just Route.SpaceSettings

        Blank ->
            Nothing

        NotFound ->
            Nothing


pageView : Repo -> SharedState -> Page -> Html Msg
pageView repo sharedState page =
    case page of
        SetupCreateGroups pageModel ->
            pageModel
                |> Page.Setup.CreateGroups.view
                |> Html.map SetupCreateGroupsMsg

        SetupInviteUsers pageModel ->
            pageModel
                |> Page.Setup.InviteUsers.view
                |> Html.map SetupInviteUsersMsg

        Inbox ->
            sharedState.featuredUsers
                |> Page.Inbox.view repo
                |> Html.map InboxMsg

        Groups pageModel ->
            pageModel
                |> Page.Groups.view repo
                |> Html.map GroupsMsg

        Group pageModel ->
            pageModel
                |> Page.Group.view repo
                |> Html.map GroupMsg

        NewGroup pageModel ->
            pageModel
                |> Page.NewGroup.view
                |> Html.map NewGroupMsg

        Post pageModel ->
            pageModel
                |> Page.Post.view repo
                |> Html.map PostMsg

        UserSettings pageModel ->
            pageModel
                |> Page.UserSettings.view repo
                |> Html.map UserSettingsMsg

        SpaceSettings pageModel ->
            pageModel
                |> Page.SpaceSettings.view repo
                |> Html.map SpaceSettingsMsg

        Blank ->
            text ""

        NotFound ->
            text "404"



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
    case model.page of
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



-- VIEW


view : Model -> Html Msg
view model =
    case model.sharedState of
        NotLoaded ->
            text ""

        Loaded sharedState ->
            div []
                [ leftSidebar sharedState model
                , pageView model.repo sharedState model.page
                ]


leftSidebar : SharedState -> Model -> Html Msg
leftSidebar sharedState ({ page, repo } as model) =
    let
        currentUserData =
            Repo.getSpaceUser repo sharedState.user

        spaceData =
            Repo.getSpace repo sharedState.space
    in
        div [ class "fixed bg-grey-lighter border-r w-48 h-full min-h-screen" ]
            [ div [ class "p-4" ]
                [ div [ class "ml-2" ]
                    [ div [ class "mb-2" ] [ thingAvatar Avatar.Small spaceData ]
                    , div [ class "mb-6 font-extrabold text-lg text-dusty-blue-darker tracking-semi-tight" ] [ text spaceData.name ]
                    ]
                , ul [ class "mb-4 list-reset leading-semi-loose select-none" ]
                    [ sidebarLink "Inbox" (Just Route.Inbox) page
                    , sidebarLink "Everything" Nothing page
                    , sidebarLink "Drafts" Nothing page
                    ]
                , groupLinks repo sharedState.bookmarkedGroups page
                , sidebarLink "Groups" (Just Route.Groups) page
                ]
            , div [ class "absolute pin-b w-full" ]
                [ a [ Route.href (Route.UserSettings), class "flex p-4 no-underline border-turquoise hover:bg-grey transition-bg" ]
                    [ div [] [ personAvatar Avatar.Small currentUserData ]
                    , div [ class "ml-2 -mt-1 text-sm text-dusty-blue-darker leading-normal" ]
                        [ div [] [ text "Signed in as" ]
                        , div [ class "font-bold" ] [ text (displayName currentUserData) ]
                        ]
                    ]
                ]
            ]


groupLinks : Repo -> List Group -> Page -> Html Msg
groupLinks repo groups currentPage =
    let
        linkify group =
            sidebarLink group.name (Just <| Route.Group group.id) currentPage

        links =
            groups
                |> Repo.getGroups repo
                |> List.sortBy .name
                |> List.map linkify
    in
        ul [ class "mb-4 list-reset leading-semi-loose select-none" ] links


{-| Build a link for the sidebar navigation with a special indicator for the
current page. Pass Nothing for the route to make it a placeholder link.
-}
sidebarLink : String -> Maybe Route -> Page -> Html Msg
sidebarLink title maybeRoute currentPage =
    let
        link route =
            a
                [ route
                , class "ml-2 text-dusty-blue-darkest no-underline truncate"
                ]
                [ text title ]
    in
        case ( maybeRoute, routeFor currentPage ) of
            ( Just route, Just currentRoute ) ->
                if route == currentRoute then
                    li [ class "flex items-center font-bold" ]
                        [ div [ class "-ml-1 w-1 h-5 bg-turquoise rounded-full" ] []
                        , link (Route.href route)
                        ]
                else
                    li [ class "flex" ] [ link (Route.href route) ]

            ( _, _ ) ->
                li [ class "flex" ] [ link (href "#") ]



-- PROGRAM


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChanged
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
