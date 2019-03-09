module Page.Post exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, receivePresence, setup, subscriptions, teardown, title, update, view)

import Browser.Navigation as Nav
import Connection
import Device exposing (Device)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Id exposing (Id)
import Json.Decode as Decode
import KeyboardShortcuts exposing (Modifier(..))
import Layout.SpaceDesktop
import Layout.SpaceMobile
import Lazy exposing (Lazy(..))
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.ClosePost as ClosePost
import Mutation.DismissNotifications as DismissNotifications
import Mutation.DismissPosts as DismissPosts
import Mutation.MarkAsRead as MarkAsRead
import Mutation.RecordPostView as RecordPostView
import Mutation.RecordReplyViews as RecordReplyViews
import Mutation.ReopenPost as ReopenPost
import Post exposing (Post)
import PostEditor
import PostView exposing (PostView)
import Presence exposing (Presence, PresenceList)
import Query.GetSpaceUser as GetSpaceUser
import Query.PostInit as PostInit
import Reply exposing (Reply)
import ReplySet
import Repo exposing (Repo)
import Route exposing (Route)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import TimeWithZone exposing (TimeWithZone)
import View.Helpers exposing (viewIf)
import View.PresenceList



-- MODEL


type alias Model =
    { spaceSlug : String
    , postId : Id
    , viewerId : Id
    , spaceId : Id
    , postView : PostView
    , currentViewers : Lazy PresenceList
    , isChangingState : Bool
    , isChangingInboxState : Bool

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , post : Post
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Repo.getPost model.postId repo)



-- PAGE PROPERTIES


title : Model -> String
title model =
    "View post"


viewingTopic : Model -> String
viewingTopic { postView } =
    "posts:" ++ postView.id



-- LIFECYCLE


init : String -> Id -> Globals -> Task Session.Error ( Globals, Model )
init spaceSlug postId globals =
    globals.session
        |> PostInit.request spaceSlug postId
        |> Task.map (buildModel spaceSlug globals)


buildModel : String -> Globals -> ( Session, PostInit.Response ) -> ( Globals, Model )
buildModel spaceSlug globals ( newSession, resp ) =
    let
        newRepo =
            Repo.union resp.repo globals.repo

        newGlobals =
            { globals | repo = newRepo, session = newSession }

        postView =
            PostView.init newGlobals.repo 20 resp.resolvedPost.post

        model =
            Model
                spaceSlug
                postView.id
                resp.viewerId
                resp.spaceId
                postView
                NotLoaded
                False
                False
                False
                False
    in
    ( newGlobals, model )


setup : Globals -> Model -> Cmd Msg
setup globals ({ postView } as model) =
    Cmd.batch
        [ Cmd.map PostViewMsg (PostView.setup globals postView)
        , dismissNotifications globals model
        , recordView globals model
        , recordReplyViews globals model
        , Presence.join (viewingTopic model)
        ]


teardown : Globals -> Model -> Cmd Msg
teardown globals ({ postView } as model) =
    Cmd.batch
        [ Cmd.map PostViewMsg (PostView.teardown globals postView)
        , Presence.leave (viewingTopic model)
        ]


dismissNotifications : Globals -> Model -> Cmd Msg
dismissNotifications globals model =
    globals.session
        |> DismissNotifications.request (DismissNotifications.variables (Just <| "post:" ++ model.postId))
        |> Task.attempt NotificationsDismissed


recordView : Globals -> Model -> Cmd Msg
recordView globals model =
    globals.session
        |> RecordPostView.request model.spaceId model.postView.id Nothing
        |> Task.attempt ViewRecorded


recordReplyViews : Globals -> Model -> Cmd Msg
recordReplyViews globals model =
    let
        unviewedReplyIds =
            globals.repo
                |> Repo.getReplies (ReplySet.map .id model.postView.replyViews)
                |> List.filter (\reply -> not (Reply.hasViewed reply))
                |> List.map Reply.id
    in
    if List.length unviewedReplyIds > 0 then
        globals.session
            |> RecordReplyViews.request model.spaceId unviewedReplyIds
            |> Task.attempt ReplyViewsRecorded

    else
        Cmd.none



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | ToggleNotifications
    | InternalLinkClicked String
    | PostViewMsg PostView.Msg
    | NotificationsDismissed (Result Session.Error ( Session, DismissNotifications.Response ))
    | ViewRecorded (Result Session.Error ( Session, RecordPostView.Response ))
    | ReplyViewsRecorded (Result Session.Error ( Session, RecordReplyViews.Response ))
    | SpaceUserFetched (Result Session.Error ( Session, GetSpaceUser.Response ))
    | ClosePostClicked
    | ReopenPostClicked
    | PostClosed (Result Session.Error ( Session, ClosePost.Response ))
    | PostReopened (Result Session.Error ( Session, ReopenPost.Response ))
    | DismissPostClicked
    | PostDismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | MoveToInboxClicked
    | PostMovedToInbox (Result Session.Error ( Session, MarkAsRead.Response ))
    | BackClicked
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        ToggleNotifications ->
            ( ( model, Cmd.none ), { globals | showNotifications = not globals.showNotifications } )

        InternalLinkClicked pathname ->
            ( ( model, Nav.pushUrl globals.navKey pathname ), globals )

        PostViewMsg postViewMsg ->
            let
                ( ( newPostComp, cmd ), newGlobals ) =
                    PostView.update postViewMsg globals model.postView
            in
            ( ( { model | postView = newPostComp }
              , Cmd.map PostViewMsg cmd
              )
            , newGlobals
            )

        NotificationsDismissed (Ok ( newSession, DismissNotifications.Success maybeTopic )) ->
            let
                newRepo =
                    Repo.dismissNotifications maybeTopic globals.repo
            in
            noCmd { globals | session = newSession, repo = newRepo } model

        NotificationsDismissed (Err Session.Expired) ->
            redirectToLogin globals model

        NotificationsDismissed _ ->
            noCmd globals model

        ViewRecorded (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        ViewRecorded (Err Session.Expired) ->
            redirectToLogin globals model

        ViewRecorded (Err _) ->
            noCmd globals model

        ReplyViewsRecorded (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        ReplyViewsRecorded (Err Session.Expired) ->
            redirectToLogin globals model

        ReplyViewsRecorded (Err _) ->
            noCmd globals model

        SpaceUserFetched (Ok ( newSession, response )) ->
            let
                newRepo =
                    case response of
                        GetSpaceUser.Success spaceUser ->
                            Repo.setSpaceUser spaceUser globals.repo

                        _ ->
                            globals.repo
            in
            noCmd { globals | session = newSession, repo = newRepo } model

        SpaceUserFetched (Err Session.Expired) ->
            redirectToLogin globals model

        SpaceUserFetched (Err _) ->
            noCmd globals model

        ClosePostClicked ->
            let
                cmd =
                    globals.session
                        |> ClosePost.request model.spaceId model.postId
                        |> Task.attempt PostClosed
            in
            ( ( { model | isChangingState = True }, cmd ), globals )

        ReopenPostClicked ->
            let
                cmd =
                    globals.session
                        |> ReopenPost.request model.spaceId model.postId
                        |> Task.attempt PostReopened
            in
            ( ( { model | isChangingState = True }, cmd ), globals )

        PostClosed (Ok ( newSession, ClosePost.Success post )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setPost post
            in
            ( ( { model | isChangingState = False }, Cmd.none )
            , { globals | repo = newRepo, session = newSession }
            )

        PostClosed (Ok ( newSession, ClosePost.Invalid errors )) ->
            ( ( { model | isChangingState = False }, Cmd.none )
            , { globals | session = newSession }
            )

        PostClosed (Err Session.Expired) ->
            redirectToLogin globals model

        PostClosed (Err _) ->
            noCmd globals model

        PostReopened (Ok ( newSession, ReopenPost.Success post )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setPost post
            in
            ( ( { model | isChangingState = False }, Cmd.none )
            , { globals | repo = newRepo, session = newSession }
            )

        PostReopened (Ok ( newSession, ReopenPost.Invalid errors )) ->
            ( ( { model | isChangingState = False }, Cmd.none )
            , { globals | session = newSession }
            )

        PostReopened (Err Session.Expired) ->
            redirectToLogin globals model

        PostReopened (Err _) ->
            noCmd globals model

        DismissPostClicked ->
            let
                cmd =
                    globals.session
                        |> DismissPosts.request model.spaceId [ model.postId ]
                        |> Task.attempt PostDismissed
            in
            ( ( { model | isChangingInboxState = True }, cmd ), globals )

        PostDismissed (Ok ( newSession, _ )) ->
            ( ( { model | isChangingInboxState = False }, Cmd.none ), { globals | session = newSession } )

        PostDismissed (Err Session.Expired) ->
            redirectToLogin globals model

        PostDismissed (Err _) ->
            noCmd globals { model | isChangingInboxState = True }

        MoveToInboxClicked ->
            let
                cmd =
                    globals.session
                        |> MarkAsRead.request model.spaceId [ model.postId ]
                        |> Task.attempt PostMovedToInbox
            in
            ( ( { model | isChangingInboxState = True }, cmd ), globals )

        PostMovedToInbox (Ok ( newSession, _ )) ->
            ( ( { model | isChangingInboxState = False }, Cmd.none ), { globals | session = newSession } )

        PostMovedToInbox (Err Session.Expired) ->
            redirectToLogin globals model

        PostMovedToInbox (Err _) ->
            noCmd globals { model | isChangingInboxState = True }

        BackClicked ->
            ( ( model, Nav.back globals.navKey 1 ), globals )

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



-- INBOUND EVENTS


consumeEvent : Globals -> Event -> Model -> ( Model, Cmd Msg )
consumeEvent globals event model =
    case event of
        Event.ReplyCreated reply ->
            let
                ( newPostComp, cmd ) =
                    PostView.refreshFromCache globals model.postView

                viewCmd =
                    globals.session
                        |> RecordReplyViews.request model.spaceId [ Reply.id reply ]
                        |> Task.attempt ReplyViewsRecorded

                scrollCmd =
                    Scroll.toBottom Scroll.Document
            in
            ( { model | postView = newPostComp }
            , Cmd.batch [ Cmd.map PostViewMsg cmd, viewCmd, scrollCmd ]
            )

        _ ->
            ( model, Cmd.none )


receivePresence : Presence.Event -> Globals -> Model -> ( Model, Cmd Msg )
receivePresence event globals model =
    case event of
        Presence.Sync topic list ->
            if topic == viewingTopic model then
                handleSync list model

            else
                ( model, Cmd.none )

        Presence.Join topic presence ->
            if topic == viewingTopic model then
                handleJoin presence globals model

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


handleSync : PresenceList -> Model -> ( Model, Cmd Msg )
handleSync list model =
    ( { model | currentViewers = Loaded list }, Cmd.none )


handleJoin : Presence -> Globals -> Model -> ( Model, Cmd Msg )
handleJoin presence globals model =
    case Repo.getSpaceUserByUserId model.spaceId (Presence.getUserId presence) globals.repo of
        Just _ ->
            ( model, Cmd.none )

        Nothing ->
            ( model
            , globals.session
                |> GetSpaceUser.request model.spaceId (Presence.getUserId presence)
                |> Task.attempt SpaceUserFetched
            )



-- EVENTS


consumeKeyboardEvent : Globals -> KeyboardShortcuts.Event -> Model -> ( ( Model, Cmd Msg ), Globals )
consumeKeyboardEvent globals event model =
    case ( event.key, event.modifiers ) of
        ( "e", [] ) ->
            let
                cmd =
                    globals.session
                        |> DismissPosts.request model.spaceId [ model.postView.id ]
                        |> Task.attempt PostDismissed
            in
            ( ( model, cmd ), globals )

        ( "e", [ Meta ] ) ->
            let
                cmd =
                    globals.session
                        |> MarkAsRead.request model.spaceId [ model.postView.id ]
                        |> Task.attempt PostMovedToInbox
            in
            ( ( model, cmd ), globals )

        ( "y", [] ) ->
            let
                cmd =
                    globals.session
                        |> ClosePost.request model.spaceId model.postView.id
                        |> Task.attempt PostClosed
            in
            ( ( model, cmd ), globals )

        ( "r", [] ) ->
            let
                ( ( newPostView, compCmd ), newGlobals ) =
                    PostView.expandReplyComposer globals model.postView
            in
            ( ( { model | postView = newPostView }
              , Cmd.map PostViewMsg compCmd
              )
            , globals
            )

        _ ->
            ( ( model, Cmd.none ), globals )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.none



-- VIEW


view : Globals -> Model -> Html Msg
view globals model =
    case resolveData globals.repo model of
        Just data ->
            resolvedView globals model data

        Nothing ->
            text "Something went wrong."


resolvedView : Globals -> Model -> Data -> Html Msg
resolvedView globals model data =
    case globals.device of
        Device.Desktop ->
            resolvedDesktopView globals model data

        Device.Mobile ->
            resolvedMobileView globals model data



-- DESKTOP


resolvedDesktopView : Globals -> Model -> Data -> Html Msg
resolvedDesktopView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            , onPageClicked = NoOp
            }

        postConfig =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = globals.now
            , spaceUsers = Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo
            , groups = Repo.getGroups (Space.groupIds data.space) globals.repo
            , showGroups = True
            , isSelected = False
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 max-w-lg leading-normal" ]
            [ div []
                [ div [ class "sticky flex items-center pin-t mb-6 py-2 trans-border-b-grey bg-white z-40" ]
                    [ button
                        [ buttonClasses
                        , onClick BackClicked
                        ]
                        [ text "Back" ]
                    , inboxStateButton model.isChangingInboxState data.post
                    , postStateButton model.isChangingState data.post
                    ]
                , model.postView
                    |> PostView.view postConfig
                    |> Html.map PostViewMsg
                ]
            , Layout.SpaceDesktop.rightSidebar <|
                sidebarView globals.repo model data
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = "Post"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
            , rightControl = Layout.SpaceMobile.ShowSidebar
            }

        postConfig =
            { globals = globals
            , space = data.space
            , currentUser = data.viewer
            , now = globals.now
            , spaceUsers = Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo
            , groups = Repo.getGroups (Space.groupIds data.space) globals.repo
            , showGroups = True
            , isSelected = False
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "mx-auto leading-normal" ]
            [ div [ class "px-3 pt-5" ]
                [ model.postView
                    |> PostView.view postConfig
                    |> Html.map PostViewMsg
                ]
            , viewIf model.showSidebar <|
                Layout.SpaceMobile.rightSidebar config
                    [ div [ class "p-6" ] (sidebarView globals.repo model data)
                    ]
            ]
        ]



-- SHARED


buttonClasses : Attribute msg
buttonClasses =
    classList
        [ ( "flex items-center justify-center px-4 h-9 rounded-full no-outline", True )
        , ( "text-dusty-blue hover:text-dusty-blue-dark text-md font-bold", True )
        , ( "bg-transparent hover:bg-grey transition-bg", True )
        , ( "mr-2", True )
        ]


inboxStateButton : Bool -> Post -> Html Msg
inboxStateButton isChangingInboxState post =
    case Post.inboxState post of
        Post.Excluded ->
            button
                [ buttonClasses
                , onClick MoveToInboxClicked
                , disabled isChangingInboxState
                ]
                [ text "Add to my inbox" ]

        Post.Unread ->
            button
                [ buttonClasses
                , onClick DismissPostClicked
                , disabled isChangingInboxState
                ]
                [ text "Dismiss from my inbox" ]

        Post.Read ->
            button
                [ buttonClasses
                , onClick DismissPostClicked
                , disabled isChangingInboxState
                ]
                [ text "Dismiss from my inbox" ]

        Post.Dismissed ->
            button
                [ buttonClasses
                , onClick MoveToInboxClicked
                , disabled isChangingInboxState
                ]
                [ text "Add to my inbox" ]


postStateButton : Bool -> Post -> Html Msg
postStateButton isChangingState post =
    case Post.state post of
        Post.Open ->
            button
                [ buttonClasses
                , onClick ClosePostClicked
                , disabled isChangingState
                ]
                [ text "Mark as resolved" ]

        Post.Closed ->
            button
                [ buttonClasses
                , onClick ReopenPostClicked
                , disabled isChangingState
                ]
                [ text "Mark as open" ]

        _ ->
            text ""


sidebarView : Repo -> Model -> Data -> List (Html Msg)
sidebarView repo model data =
    let
        listView =
            case model.currentViewers of
                Loaded state ->
                    View.PresenceList.view repo data.space state

                NotLoaded ->
                    div [ class "pb-4 text-sm" ] [ text "Loading..." ]
    in
    [ h3 [ class "mb-2 text-base font-bold" ] [ text "Who’s Here" ]
    , listView
    ]
