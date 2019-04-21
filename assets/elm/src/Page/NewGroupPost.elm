module Page.NewGroupPost exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
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
import PageError exposing (PageError)
import Pagination
import Post exposing (Post)
import PostEditor exposing (PostEditor)
import PostView
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
            "Post to #" ++ Group.name group

        Nothing ->
            "Post to Group"



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( Globals, Model )
init params globals =
    let
        maybeUserId =
            Session.getUserId globals.session

        maybeSpaceId =
            globals.repo
                |> Repo.getSpaceBySlug (Route.NewGroupPost.getSpaceSlug params)
                |> Maybe.andThen (Just << Space.id)

        maybeGroupId =
            case maybeSpaceId of
                Just spaceId ->
                    globals.repo
                        |> Repo.getGroupByName spaceId (Route.NewGroupPost.getGroupName params)
                        |> Maybe.andThen (Just << Group.id)

                Nothing ->
                    Nothing

        maybeViewerId =
            case ( maybeSpaceId, maybeUserId ) of
                ( Just spaceId, Just userId ) ->
                    Repo.getSpaceUserByUserId spaceId userId globals.repo
                        |> Maybe.andThen (Just << SpaceUser.id)

                _ ->
                    Nothing
    in
    case ( maybeViewerId, maybeSpaceId, maybeGroupId ) of
        ( Just viewerId, Just spaceId, Just groupId ) ->
            let
                model =
                    Model
                        params
                        viewerId
                        spaceId
                        groupId
                        (PostEditor.init ("post-composer-" ++ groupId))
                        False
                        False
            in
            Task.succeed ( globals, model )

        _ ->
            Task.fail PageError.NotFound


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
    | PostEditorEventReceived Decode.Value
    | NewPostBodyChanged String
    | NewPostFileAdded File
    | NewPostFileUploadProgress Id Int
    | NewPostFileUploaded Id Id String
    | NewPostFileUploadError Id
    | ToggleUrgent
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

        ToggleUrgent ->
            ( ( { model | postComposer = PostEditor.toggleIsUrgent model.postComposer }, Cmd.none ), globals )

        NewPostSubmit ->
            if PostEditor.isSubmittable model.postComposer then
                let
                    variables =
                        CreatePost.variables
                            model.spaceId
                            (Just model.groupId)
                            []
                            (PostEditor.getBody model.postComposer)
                            (PostEditor.getUploadIds model.postComposer)
                            (PostEditor.getIsUrgent model.postComposer)

                    cmd =
                        globals.session
                            |> CreatePost.request variables
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
                            (Route.NewGroupPost.getGroupName model.params)
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
    text ""



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        groupRoute =
            Route.Group <| Route.Group.init (Route.NewGroupPost.getSpaceSlug model.params) (Route.NewGroupPost.getGroupName model.params)

        layoutConfig =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = title globals.repo model
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
            , spaceUsers = Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo
            , groups = Repo.getGroups (Space.groupIds data.space) globals.repo
            , onFileAdded = NewPostFileAdded
            , onFileUploadProgress = NewPostFileUploadProgress
            , onFileUploaded = NewPostFileUploaded
            , onFileUploadError = NewPostFileUploadError
            , classList = []
            }
    in
    Layout.SpaceMobile.layout layoutConfig
        [ PostEditor.wrapper composerConfig
            [ textarea
                [ id (PostEditor.getTextareaId editor)
                , class "w-full h-24 p-4 no-outline bg-transparent text-dusty-blue-darkest text-lg resize-none leading-normal"
                , placeholder "Compose a new post..."
                , onInput NewPostBodyChanged
                , readonly (PostEditor.isSubmitting editor)
                , value (PostEditor.getBody editor)
                ]
                []
            , div [ class "p-3" ]
                [ PostEditor.filesView editor
                ]
            ]
        , div [ class "p-3" ]
            [ viewUnless (PostEditor.getIsUrgent editor) <|
                button
                    [ class "flex items-center mr-2 p-2 pr-3 rounded-full bg-grey-light hover:bg-grey transition-bg no-outline text-dusty-blue"
                    , onClick ToggleUrgent
                    ]
                    [ div [ class "mr-2 flex-no-grow" ] [ Icons.alert Icons.Off ]
                    , div [] [ text "Click to interrupt @mentioned people" ]
                    ]
            , viewIf (PostEditor.getIsUrgent editor) <|
                button
                    [ class "flex items-center mr-2 p-2 pr-3 rounded-full bg-grey-light hover:bg-grey transition-bg no-outline text-red text-md font-bold"
                    , onClick ToggleUrgent
                    ]
                    [ div [ class "mr-2 flex-no-grow" ] [ Icons.alert Icons.On ]
                    , div [] [ text "Click to interrupt nobody" ]
                    ]
            ]
        ]
