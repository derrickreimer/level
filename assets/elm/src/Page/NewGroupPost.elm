module Page.NewGroupPost exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import FieldEditor exposing (FieldEditor)
import File exposing (File)
import Globals exposing (Globals)
import Group exposing (Group)
import GroupMembership exposing (GroupMembership, GroupMembershipState(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Json.Decode as Decode
import KeyboardShortcuts
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.BookmarkGroup as BookmarkGroup
import Mutation.CloseGroup as CloseGroup
import Mutation.CreatePost as CreatePost
import Mutation.ReopenGroup as ReopenGroup
import Mutation.SubscribeToGroup as SubscribeToGroup
import Mutation.UnbookmarkGroup as UnbookmarkGroup
import Mutation.UnsubscribeFromGroup as UnsubscribeFromGroup
import Mutation.UpdateGroup as UpdateGroup
import Pagination
import Post exposing (Post)
import PostEditor exposing (PostEditor)
import Query.FeaturedMemberships as FeaturedMemberships
import Query.NewGroupPostInit as NewGroupPostInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.GroupSettings
import Route.NewGroupPost exposing (Params(..))
import Route.Search
import Route.SpaceUser
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import SpaceUserLists exposing (SpaceUserLists)
import Subscription.GroupSubscription as GroupSubscription
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import ValidationError exposing (ValidationError)
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (selectValue, setFocus, smartFormatTime, viewIf, viewUnless)
import View.SearchBox



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , groupId : Id
    , now : ( Zone, Posix )
    , postComposer : PostEditor

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , group : Group
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Repo.getGroup model.groupId repo)



-- PAGE PROPERTIES


title : Repo -> Model -> String
title repo model =
    case Repo.getGroup model.groupId repo of
        Just group ->
            "Post to " ++ Group.name group

        Nothing ->
            "Post to Group"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> NewGroupPostInit.request params 10
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( ( Session, NewGroupPostInit.Response ), ( Zone, Posix ) ) -> ( Globals, Model )
buildModel params globals ( ( newSession, resp ), now ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.groupId
                now
                (PostEditor.init ("post-composer-" ++ resp.groupId))
                False
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    let
        pageCmd =
            Cmd.batch
                [ setFocus (PostEditor.getTextareaId model.postComposer) NoOp
                , setupSockets model.groupId
                , PostEditor.fetchLocal model.postComposer
                ]
    in
    Cmd.batch
        [ pageCmd
        , Scroll.toDocumentTop NoOp
        ]


teardown : Model -> Cmd Msg
teardown model =
    let
        pageCmd =
            teardownSockets model.groupId
    in
    Cmd.batch [ pageCmd ]


setupSockets : Id -> Cmd Msg
setupSockets groupId =
    GroupSubscription.subscribe groupId


teardownSockets : Id -> Cmd Msg
teardownSockets groupId =
    GroupSubscription.unsubscribe groupId



-- UPDATE


type Msg
    = NoOp
    | Tick Posix
    | SetCurrentTime Posix Zone
    | PostEditorEventReceived Decode.Value
    | NewPostBodyChanged String
    | NewPostFileAdded File
    | NewPostFileUploadProgress Id Int
    | NewPostFileUploaded Id Id String
    | NewPostFileUploadError Id
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, CreatePost.Response ))
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), globals )

        SetCurrentTime posix zone ->
            noCmd globals { model | now = ( zone, posix ) }

        PostEditorEventReceived value ->
            case PostEditor.decodeEvent value of
                PostEditor.LocalDataFetched id body ->
                    if id == PostEditor.getId model.postComposer then
                        let
                            newPostComposer =
                                PostEditor.setBody body model.postComposer
                        in
                        ( ( { model | postComposer = newPostComposer }
                          , Cmd.none
                          )
                        , globals
                        )

                    else
                        noCmd globals model

                PostEditor.Unknown ->
                    noCmd globals model

        NewPostBodyChanged value ->
            let
                newPostComposer =
                    PostEditor.setBody value model.postComposer
            in
            ( ( { model | postComposer = newPostComposer }
              , PostEditor.saveLocal newPostComposer
              )
            , globals
            )

        NewPostFileAdded file ->
            noCmd globals { model | postComposer = PostEditor.addFile file model.postComposer }

        NewPostFileUploadProgress clientId percentage ->
            noCmd globals { model | postComposer = PostEditor.setFileUploadPercentage clientId percentage model.postComposer }

        NewPostFileUploaded clientId fileId url ->
            let
                newPostComposer =
                    model.postComposer
                        |> PostEditor.setFileState clientId (File.Uploaded fileId url)

                cmd =
                    newPostComposer
                        |> PostEditor.insertFileLink fileId
            in
            ( ( { model | postComposer = newPostComposer }, cmd ), globals )

        NewPostFileUploadError clientId ->
            noCmd globals { model | postComposer = PostEditor.setFileState clientId File.UploadError model.postComposer }

        NewPostSubmit ->
            if PostEditor.isSubmittable model.postComposer then
                let
                    cmd =
                        globals.session
                            |> CreatePost.request model.spaceId model.groupId (PostEditor.getBody model.postComposer) (PostEditor.getUploadIds model.postComposer)
                            |> Task.attempt NewPostSubmitted
                in
                ( ( { model | postComposer = PostEditor.setToSubmitting model.postComposer }, cmd ), globals )

            else
                noCmd globals model

        NewPostSubmitted (Ok ( newSession, response )) ->
            let
                redirectTo =
                    Route.Group <|
                        Route.Group.init
                            (Route.NewGroupPost.getSpaceSlug model.params)
                            (Route.NewGroupPost.getGroupId model.params)
            in
            ( ( model, Route.pushUrl globals.navKey redirectTo )
            , { globals | session = newSession }
            )

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewPostSubmitted (Err _) ->
            { model | postComposer = PostEditor.setNotSubmitting model.postComposer }
                |> noCmd globals

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



-- EVENTS


consumeEvent : Event -> Session -> Model -> ( Model, Cmd Msg )
consumeEvent event session model =
    ( model, Cmd.none )



-- SUBSCRIPTION


subscriptions : Sub Msg
subscriptions =
    Sub.none



-- VIEW


view : Globals -> Model -> Html Msg
view globals model =
    let
        spaceUsers =
            SpaceUserLists.resolveList globals.repo model.spaceId globals.spaceUserLists
    in
    case resolveData globals.repo model of
        Just data ->
            resolvedView globals spaceUsers model data

        Nothing ->
            text "Something went wrong."


resolvedView : Globals -> List SpaceUser -> Model -> Data -> Html Msg
resolvedView globals spaceUsers model data =
    case globals.device of
        Device.Desktop ->
            resolvedDesktopView globals spaceUsers model data

        Device.Mobile ->
            resolvedMobileView globals spaceUsers model data



-- DESKTOP


resolvedDesktopView : Globals -> List SpaceUser -> Model -> Data -> Html Msg
resolvedDesktopView globals spaceUsers model data =
    text ""



-- MOBILE


resolvedMobileView : Globals -> List SpaceUser -> Model -> Data -> Html Msg
resolvedMobileView globals spaceUsers model data =
    let
        groupRoute =
            Route.Group <| Route.Group.init (Route.NewGroupPost.getSpaceSlug model.params) (Route.NewGroupPost.getGroupId model.params)

        layoutConfig =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = []
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "Post to " ++ Group.name data.group
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.Back groupRoute
            , rightControl =
                Layout.SpaceMobile.Custom <|
                    button
                        [ class "btn btn-blue flex items-center justify-center w-9 h-9 p-0"
                        , onClick NewPostSubmit
                        , disabled (PostEditor.isUnsubmittable editor)
                        ]
                        [ Icons.sendWhite ]
            }

        editor =
            model.postComposer

        composerConfig =
            { editor = editor
            , spaceId = model.spaceId
            , spaceUsers = spaceUsers
            , onFileAdded = NewPostFileAdded
            , onFileUploadProgress = NewPostFileUploadProgress
            , onFileUploaded = NewPostFileUploaded
            , onFileUploadError = NewPostFileUploadError
            , classList = [ ( "absolute w-full pin-t-mobile pin-b", True ) ]
            }
    in
    Layout.SpaceMobile.layout layoutConfig
        [ div [ class "mx-auto leading-normal" ]
            [ PostEditor.wrapper composerConfig
                [ textarea
                    [ id (PostEditor.getTextareaId editor)
                    , class "w-full p-4 no-outline bg-transparent text-dusty-blue-darkest text-lg resize-none leading-normal"
                    , placeholder "Compose a new post..."
                    , onInput NewPostBodyChanged
                    , readonly (PostEditor.isSubmitting editor)
                    , value (PostEditor.getBody editor)
                    ]
                    []
                , div [ class "p-4" ]
                    [ PostEditor.filesView editor
                    ]
                ]
            ]
        ]
