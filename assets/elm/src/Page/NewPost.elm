module Page.NewPost exposing (Model, Msg(..), consumeEvent, consumeKeyboardEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar
import Browser.Navigation as Nav
import Device exposing (Device)
import Event exposing (Event)
import File exposing (File)
import Globals exposing (Globals)
import Group exposing (Group)
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
import Mutation.CreatePost as CreatePost
import PostEditor exposing (PostEditor)
import Query.SetupInit as SetupInit
import Regex exposing (Regex)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.Groups
import Route.NewPost exposing (Params)
import Route.Posts
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import ValidationError exposing (ValidationError, errorView, errorsFor, isInvalid)
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, viewIf, viewUnless)



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , postComposer : PostEditor
    , isSubmitting : Bool
    , errors : List ValidationError

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    }


type Recipient
    = Nobody
    | Direct
    | Channel


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)



-- PAGE PROPERTIES


title : Model -> String
title model =
    "New Post"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> SetupInit.request (Route.NewPost.getSpaceSlug params)
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, SetupInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                (PostEditor.init "global-post-composer")
                False
                []
                False
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.batch
        [ setFocus (PostEditor.getTextareaId model.postComposer) NoOp
        , Scroll.toDocumentTop NoOp
        , PostEditor.fetchLocal model.postComposer
        ]


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp
    | ToggleKeyboardCommands
    | PostEditorEventReceived Decode.Value
    | NewPostBodyChanged String
    | NewPostFileAdded File
    | NewPostFileUploadProgress Id Int
    | NewPostFileUploaded Id Id String
    | NewPostFileUploadError Id
    | ToggleUrgent
    | NewPostSubmit
    | NewPostSubmitted (Result Session.Error ( Session, CreatePost.Response ))
    | EscapePressed
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

        ToggleUrgent ->
            ( ( { model | postComposer = PostEditor.toggleIsUrgent model.postComposer }, Cmd.none ), globals )

        NewPostSubmit ->
            if PostEditor.isSubmittable model.postComposer then
                let
                    variables =
                        CreatePost.variablesWithoutGroup
                            model.spaceId
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
                ( newPostComposer, postCmd ) =
                    model.postComposer
                        |> PostEditor.reset

                redirectCmd =
                    Route.pushUrl globals.navKey (Route.Posts (Route.Posts.init (Route.NewPost.getSpaceSlug model.params)))
            in
            ( ( { model | postComposer = newPostComposer }, Cmd.batch [ postCmd, redirectCmd ] )
            , { globals | session = newSession }
            )

        NewPostSubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewPostSubmitted (Err _) ->
            { model | postComposer = PostEditor.setNotSubmitting model.postComposer }
                |> noCmd globals

        NewPostFileUploadError clientId ->
            noCmd globals { model | postComposer = PostEditor.setFileState clientId File.UploadError model.postComposer }

        EscapePressed ->
            handleEscapePressed globals model

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


handleEscapePressed : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
handleEscapePressed globals model =
    let
        cmd =
            if PostEditor.getBody model.postComposer == "" then
                Route.pushUrl globals.navKey (Route.Posts (Route.Posts.init (Route.NewPost.getSpaceSlug model.params)))

            else
                Cmd.none
    in
    ( ( model, cmd ), globals )



-- EVENTS


consumeEvent : Globals -> Event -> Model -> ( Model, Cmd Msg )
consumeEvent globals event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        _ ->
            ( model, Cmd.none )


consumeKeyboardEvent : Globals -> KeyboardShortcuts.Event -> Model -> ( ( Model, Cmd Msg ), Globals )
consumeKeyboardEvent globals event model =
    case ( event.key, event.modifiers ) of
        ( "Escape", [] ) ->
            handleEscapePressed globals model

        _ ->
            ( ( model, Cmd.none ), globals )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    PostEditor.receive PostEditorEventReceived



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
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , showKeyboardCommands = globals.showKeyboardCommands
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto px-8 py-4 max-w-lg leading-normal" ]
            [ desktopPostComposerView globals model data
            , p [ class "px-8 text-md text-dusty-blue-dark text-center" ]
                [ span [ class "-mt-1 mr-2 inline-block align-middle" ] [ Icons.hash ]
                , text "Hashtag the Channels where you'd like your message to appear."
                ]
            ]
        ]


desktopPostComposerView : Globals -> Model -> Data -> Html Msg
desktopPostComposerView globals model data =
    let
        editor =
            model.postComposer

        config =
            { editor = editor
            , spaceId = Space.id data.space
            , spaceUsers = Repo.getSpaceUsers (Space.spaceUserIds data.space) globals.repo
            , groups = Repo.getGroups (Space.groupIds data.space) globals.repo
            , onFileAdded = NewPostFileAdded
            , onFileUploadProgress = NewPostFileUploadProgress
            , onFileUploaded = NewPostFileUploaded
            , onFileUploadError = NewPostFileUploadError
            , classList = []
            }

        buttonText =
            if PostEditor.getBody editor == "" then
                "Send"

            else
                case determineRecipient (PostEditor.getBody editor) of
                    Nobody ->
                        "Save Private Note"

                    Direct ->
                        "Send Direct Message "

                    Channel ->
                        "Send to Channel"
    in
    PostEditor.wrapper config
        [ label [ class "composer mb-4" ]
            [ div [ class "flex" ]
                [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Medium data.viewer ]
                , div [ class "flex-grow pl-2 pt-2" ]
                    [ textarea
                        [ id (PostEditor.getTextareaId editor)
                        , class "w-full h-8 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                        , placeholder "Compose a new post..."
                        , onInput NewPostBodyChanged
                        , onKeydown preventDefault
                            [ ( [ Keys.Meta ], enter, \event -> NewPostSubmit )
                            , ( [], esc, \event -> EscapePressed )
                            ]
                        , readonly (PostEditor.isSubmitting editor)
                        , value (PostEditor.getBody editor)
                        , tabindex 1
                        ]
                        []
                    , PostEditor.filesView editor
                    , div [ class "flex items-center justify-end" ]
                        [ viewUnless (PostEditor.getIsUrgent editor) <|
                            button
                                [ class "tooltip tooltip-bottom mr-2 p-1 rounded-full bg-grey-light hover:bg-grey transition-bg no-outline"
                                , attribute "data-tooltip" "Interrupt all @mentioned people"
                                , onClick ToggleUrgent
                                ]
                                [ Icons.alert Icons.Off ]
                        , viewIf (PostEditor.getIsUrgent editor) <|
                            button
                                [ class "tooltip tooltip-bottom mr-2 p-1 rounded-full bg-grey-light hover:bg-grey transition-bg no-outline"
                                , attribute "data-tooltip" "Don't interrupt anyone"
                                , onClick ToggleUrgent
                                ]
                                [ Icons.alert Icons.On ]
                        , button
                            [ class "btn btn-blue btn-md"
                            , onClick NewPostSubmit
                            , disabled (isUnsubmittable editor)
                            , tabindex 3
                            ]
                            [ text buttonText ]
                        ]
                    ]
                ]
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        layoutConfig =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = []
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "New Post"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.ShowNav
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
        [ p [ class "px-3 py-3 text-sm text-dusty-blue-dark" ]
            [ span [ class "-mt-1 mr-2 inline-block align-middle" ] [ Icons.hash ]
            , text "Hashtag one or more Channels in your message."
            ]
        , PostEditor.wrapper composerConfig
            [ textarea
                [ id (PostEditor.getTextareaId editor)
                , class "w-full p-4 no-outline bg-transparent text-dusty-blue-darkest text-lg resize-none leading-normal"
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



-- SHARED


isUnsubmittable : PostEditor -> Bool
isUnsubmittable editor =
    PostEditor.isUnsubmittable editor


determineRecipient : String -> Recipient
determineRecipient text =
    if Regex.contains hashtagRegex text then
        Channel

    else if Regex.contains mentionRegex text then
        Direct

    else
        Nobody


mentionRegex : Regex
mentionRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromStringWith { caseInsensitive = True, multiline = True }
            "(?:^|\\W)@(\\#?[a-z0-9][a-z0-9-]*)(?!\\/)(?=\\.+[ \\t\\W]|\\.+$|[^0-9a-zA-Z_.]|$)"


hashtagRegex : Regex
hashtagRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromStringWith { caseInsensitive = True, multiline = True }
            "(?:^|\\W)\\#([a-z0-9][a-z0-9-]*)(?!\\/)(?=\\.+[ \\t\\W]|\\.+$|[^0-9a-zA-Z_.]|$)"
