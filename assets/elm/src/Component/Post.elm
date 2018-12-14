module Component.Post exposing (Mode(..), Model, Msg(..), checkableView, handleEditorEventReceived, handleReplyCreated, init, setup, teardown, update, view)

import Actor exposing (Actor)
import Avatar exposing (personAvatar)
import Color exposing (Color)
import Connection exposing (Connection)
import Dict exposing (Dict)
import File exposing (File)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, maybe, string)
import Markdown
import Mutation.CreatePostReaction as CreatePostReaction
import Mutation.CreateReply as CreateReply
import Mutation.DeletePostReaction as DeletePostReaction
import Mutation.DismissPosts as DismissPosts
import Mutation.RecordReplyViews as RecordReplyViews
import Mutation.UpdatePost as UpdatePost
import Mutation.UpdateReply as UpdateReply
import Post exposing (Post)
import PostEditor exposing (PostEditor)
import Query.Replies
import RenderedHtml
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route
import Route.Group
import Route.SpaceUser
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Subscription.PostSubscription as PostSubscription
import Task exposing (Task)
import Time exposing (Posix, Zone)
import ValidationError
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (onPassiveClick, setFocus, smartFormatTime, unsetFocus, viewIf, viewUnless)



-- MODEL


type alias Model =
    { id : String
    , mode : Mode
    , showGroups : Bool
    , spaceSlug : String
    , postId : Id
    , replyIds : Connection Id
    , replyComposer : PostEditor
    , postEditor : PostEditor
    , replyEditors : ReplyEditors
    , isChecked : Bool
    }


type Mode
    = Feed
    | FullPage


type alias Data =
    { post : Post
    , author : Actor
    }


type alias ReplyEditors =
    Dict Id PostEditor


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    let
        maybePost =
            Repo.getPost model.postId repo
    in
    case maybePost of
        Just post ->
            Maybe.map2 Data
                (Just post)
                (Repo.getActor (Post.authorId post) repo)

        Nothing ->
            Nothing



-- LIFECYCLE


init : Mode -> Bool -> String -> Id -> Connection Id -> Model
init mode showGroups spaceSlug postId replyIds =
    let
        replyComposer =
            case mode of
                Feed ->
                    postId
                        |> PostEditor.init
                        |> PostEditor.collapse

                FullPage ->
                    postId
                        |> PostEditor.init
                        |> PostEditor.expand
    in
    Model
        postId
        mode
        showGroups
        spaceSlug
        postId
        replyIds
        replyComposer
        (PostEditor.init postId)
        Dict.empty
        False


setup : Model -> Cmd Msg
setup model =
    Cmd.batch
        [ PostSubscription.subscribe model.postId
        , setupReplyComposer model.postId model.replyComposer
        , setupScrollPosition model.mode
        ]


teardown : Model -> Cmd Msg
teardown model =
    PostSubscription.unsubscribe model.postId


setupReplyComposer : String -> PostEditor -> Cmd Msg
setupReplyComposer postId replyComposer =
    if PostEditor.isExpanded replyComposer then
        let
            composerId =
                PostEditor.getTextareaId replyComposer
        in
        Cmd.batch
            [ setFocus composerId NoOp
            , PostEditor.fetchLocal replyComposer
            ]

    else
        Cmd.none


setupScrollPosition : Mode -> Cmd Msg
setupScrollPosition mode =
    case mode of
        FullPage ->
            Scroll.toBottom Scroll.Document

        _ ->
            Cmd.none



-- UPDATE


type Msg
    = NoOp
    | ExpandReplyComposer
    | NewReplyBodyChanged String
    | NewReplyFileAdded File
    | NewReplyFileUploadProgress Id Int
    | NewReplyFileUploaded Id Id String
    | NewReplyFileUploadError Id
    | NewReplyBlurred
    | NewReplySubmit
    | NewReplyEscaped
    | NewReplySubmitted (Result Session.Error ( Session, CreateReply.Response ))
    | PreviousRepliesRequested
    | PreviousRepliesFetched (Result Session.Error ( Session, Query.Replies.Response ))
    | ReplyViewsRecorded (Result Session.Error ( Session, RecordReplyViews.Response ))
    | SelectionToggled
    | DismissClicked
    | Dismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | ClickedToExpand
    | ExpandPostEditor
    | CollapsePostEditor
    | PostEditorBodyChanged String
    | PostEditorFileAdded File
    | PostEditorFileUploadProgress Id Int
    | PostEditorFileUploaded Id Id String
    | PostEditorFileUploadError Id
    | PostEditorSubmitted
    | PostUpdated (Result Session.Error ( Session, UpdatePost.Response ))
    | ExpandReplyEditor Id
    | CollapseReplyEditor Id
    | ReplyEditorBodyChanged Id String
    | ReplyEditorFileAdded Id File
    | ReplyEditorFileUploadProgress Id Id Int
    | ReplyEditorFileUploaded Id Id Id String
    | ReplyEditorFileUploadError Id Id
    | ReplyEditorSubmitted Id
    | ReplyUpdated Id (Result Session.Error ( Session, UpdateReply.Response ))
    | CreatePostReactionClicked
    | DeletePostReactionClicked
    | PostReactionCreated (Result Session.Error ( Session, CreatePostReaction.Response ))
    | PostReactionDeleted (Result Session.Error ( Session, DeletePostReaction.Response ))


update : Msg -> Id -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg spaceId globals model =
    case msg of
        NoOp ->
            noCmd globals model

        ExpandReplyComposer ->
            let
                cmd =
                    Cmd.batch
                        [ setFocus (PostEditor.getTextareaId model.replyComposer) NoOp
                        , markVisibleRepliesAsViewed globals spaceId model
                        ]

                newModel =
                    { model | replyComposer = PostEditor.expand model.replyComposer }
            in
            ( ( newModel, cmd ), globals )

        NewReplyBodyChanged val ->
            let
                newReplyComposer =
                    PostEditor.setBody val model.replyComposer
            in
            ( ( { model | replyComposer = newReplyComposer }
              , PostEditor.saveLocal newReplyComposer
              )
            , globals
            )

        NewReplyFileAdded file ->
            noCmd globals { model | replyComposer = PostEditor.addFile file model.replyComposer }

        NewReplyFileUploadProgress clientId percentage ->
            noCmd globals { model | replyComposer = PostEditor.setFileUploadPercentage clientId percentage model.replyComposer }

        NewReplyFileUploaded clientId fileId url ->
            let
                newReplyComposer =
                    model.replyComposer
                        |> PostEditor.setFileState clientId (File.Uploaded fileId url)

                cmd =
                    newReplyComposer
                        |> PostEditor.insertFileLink fileId
            in
            ( ( { model | replyComposer = newReplyComposer }, cmd ), globals )

        NewReplyFileUploadError clientId ->
            noCmd globals { model | replyComposer = PostEditor.setFileState clientId File.UploadError model.replyComposer }

        NewReplySubmit ->
            let
                newModel =
                    { model | replyComposer = PostEditor.setToSubmitting model.replyComposer }

                body =
                    PostEditor.getBody model.replyComposer

                cmd =
                    globals.session
                        |> CreateReply.request spaceId model.postId body (PostEditor.getUploadIds model.replyComposer)
                        |> Task.attempt NewReplySubmitted
            in
            ( ( newModel, cmd ), globals )

        NewReplySubmitted (Ok ( newSession, reply )) ->
            let
                ( newReplyComposer, cmd ) =
                    model.replyComposer
                        |> PostEditor.reset

                newModel =
                    { model | replyComposer = newReplyComposer }
            in
            ( ( newModel
              , Cmd.batch
                    [ setFocus (PostEditor.getTextareaId model.replyComposer) NoOp
                    , cmd
                    ]
              )
            , { globals | session = newSession }
            )

        NewReplySubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewReplySubmitted (Err _) ->
            noCmd globals model

        NewReplyEscaped ->
            if PostEditor.getBody model.replyComposer == "" && model.mode == Feed then
                ( ( { model | replyComposer = PostEditor.collapse model.replyComposer }
                  , unsetFocus (PostEditor.getTextareaId model.replyComposer) NoOp
                  )
                , globals
                )

            else
                noCmd globals model

        NewReplyBlurred ->
            noCmd globals model

        PreviousRepliesRequested ->
            case Connection.startCursor model.replyIds of
                Just cursor ->
                    let
                        cmd =
                            globals.session
                                |> Query.Replies.request spaceId model.postId cursor 10
                                |> Task.attempt PreviousRepliesFetched
                    in
                    ( ( model, cmd ), globals )

                Nothing ->
                    noCmd globals model

        PreviousRepliesFetched (Ok ( newSession, resp )) ->
            let
                maybeFirstReplyId =
                    Connection.head model.replyIds

                newReplyIds =
                    Connection.prependConnection resp.replyIds model.replyIds

                newGlobals =
                    { globals
                        | session = newSession
                        , repo = Repo.union resp.repo globals.repo
                    }

                newModel =
                    { model | replyIds = newReplyIds }

                viewCmd =
                    markVisibleRepliesAsViewed newGlobals spaceId newModel

                scrollCmd =
                    case maybeFirstReplyId of
                        Just firstReplyId ->
                            Scroll.toAnchor Scroll.Document (replyNodeId firstReplyId) 200

                        Nothing ->
                            Cmd.none
            in
            ( ( newModel, Cmd.batch [ scrollCmd, viewCmd ] ), newGlobals )

        PreviousRepliesFetched (Err Session.Expired) ->
            redirectToLogin globals model

        PreviousRepliesFetched (Err _) ->
            noCmd globals model

        ReplyViewsRecorded (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        ReplyViewsRecorded (Err Session.Expired) ->
            redirectToLogin globals model

        ReplyViewsRecorded (Err _) ->
            noCmd globals model

        SelectionToggled ->
            ( ( { model | isChecked = not model.isChecked }
              , markVisibleRepliesAsViewed globals spaceId model
              )
            , globals
            )

        DismissClicked ->
            let
                cmd =
                    globals.session
                        |> DismissPosts.request spaceId [ model.postId ]
                        |> Task.attempt Dismissed
            in
            ( ( model, cmd ), globals )

        Dismissed (Ok ( newSession, _ )) ->
            let
                nodeId =
                    replyComposerId model.postId

                newGlobals =
                    { globals
                        | session = newSession
                        , flash = Flash.set Flash.Notice "Post dismissed" 3000 globals.flash
                    }
            in
            ( ( model, setFocus nodeId NoOp ), newGlobals )

        Dismissed (Err Session.Expired) ->
            redirectToLogin globals model

        Dismissed (Err _) ->
            noCmd globals model

        ClickedToExpand ->
            ( ( model, Route.pushUrl globals.navKey (Route.Post model.spaceSlug model.postId) ), globals )

        ExpandPostEditor ->
            case resolveData globals.repo model of
                Just data ->
                    let
                        nodeId =
                            PostEditor.getTextareaId model.postEditor

                        newPostEditor =
                            model.postEditor
                                |> PostEditor.expand
                                |> PostEditor.setBody (Post.body data.post)
                                |> PostEditor.setFiles (Post.files data.post)
                                |> PostEditor.clearErrors

                        cmd =
                            Cmd.batch
                                [ setFocus nodeId NoOp
                                ]
                    in
                    ( ( { model | postEditor = newPostEditor }, cmd ), globals )

                Nothing ->
                    noCmd globals model

        CollapsePostEditor ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.collapse
            in
            ( ( { model | postEditor = newPostEditor }, Cmd.none ), globals )

        PostEditorBodyChanged val ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.setBody val
            in
            noCmd globals { model | postEditor = newPostEditor }

        PostEditorFileAdded file ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.addFile file
            in
            noCmd globals { model | postEditor = newPostEditor }

        PostEditorFileUploadProgress clientId percentage ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.setFileUploadPercentage clientId percentage
            in
            noCmd globals { model | postEditor = newPostEditor }

        PostEditorFileUploaded clientId fileId url ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.setFileState clientId (File.Uploaded fileId url)

                cmd =
                    newPostEditor
                        |> PostEditor.insertFileLink fileId
            in
            ( ( { model | postEditor = newPostEditor }, cmd ), globals )

        PostEditorFileUploadError clientId ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.setFileState clientId File.UploadError
            in
            noCmd globals { model | postEditor = newPostEditor }

        PostEditorSubmitted ->
            let
                cmd =
                    globals.session
                        |> UpdatePost.request spaceId model.postId (PostEditor.getBody model.postEditor)
                        |> Task.attempt PostUpdated

                newPostEditor =
                    model.postEditor
                        |> PostEditor.setToSubmitting
                        |> PostEditor.clearErrors
            in
            ( ( { model | postEditor = newPostEditor }, cmd ), globals )

        PostUpdated (Ok ( newSession, UpdatePost.Success post )) ->
            let
                newGlobals =
                    { globals | session = newSession, repo = Repo.setPost post globals.repo }

                newPostEditor =
                    model.postEditor
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.collapse
            in
            ( ( { model | postEditor = newPostEditor }, Cmd.none ), newGlobals )

        PostUpdated (Ok ( newSession, UpdatePost.Invalid errors )) ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.setErrors errors
            in
            ( ( { model | postEditor = newPostEditor }, Cmd.none ), globals )

        PostUpdated (Err Session.Expired) ->
            redirectToLogin globals model

        PostUpdated (Err _) ->
            let
                newPostEditor =
                    model.postEditor
                        |> PostEditor.setNotSubmitting
            in
            ( ( { model | postEditor = newPostEditor }, Cmd.none ), globals )

        ExpandReplyEditor replyId ->
            case Repo.getReply replyId globals.repo of
                Just reply ->
                    let
                        newReplyEditor =
                            model.replyEditors
                                |> getReplyEditor replyId
                                |> PostEditor.expand
                                |> PostEditor.setBody (Reply.body reply)
                                |> PostEditor.setFiles (Reply.files reply)
                                |> PostEditor.clearErrors

                        nodeId =
                            PostEditor.getTextareaId newReplyEditor

                        cmd =
                            Cmd.batch
                                [ setFocus nodeId NoOp
                                ]

                        newReplyEditors =
                            model.replyEditors
                                |> Dict.insert replyId newReplyEditor
                    in
                    ( ( { model | replyEditors = newReplyEditors }, cmd ), globals )

                Nothing ->
                    noCmd globals model

        CollapseReplyEditor replyId ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.collapse

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), globals )

        ReplyEditorBodyChanged replyId val ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setBody val

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), globals )

        ReplyEditorFileAdded replyId file ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.addFile file

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), globals )

        ReplyEditorFileUploadProgress replyId clientId percentage ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setFileUploadPercentage clientId percentage

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), globals )

        ReplyEditorFileUploaded replyId clientId fileId url ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setFileState clientId (File.Uploaded fileId url)

                cmd =
                    newReplyEditor
                        |> PostEditor.insertFileLink fileId

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, cmd ), globals )

        ReplyEditorFileUploadError replyId clientId ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setFileState clientId File.UploadError

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), globals )

        ReplyEditorSubmitted replyId ->
            let
                replyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId

                cmd =
                    globals.session
                        |> UpdateReply.request spaceId replyId (PostEditor.getBody replyEditor)
                        |> Task.attempt (ReplyUpdated replyId)

                newReplyEditor =
                    replyEditor
                        |> PostEditor.setToSubmitting
                        |> PostEditor.clearErrors

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, cmd ), globals )

        ReplyUpdated replyId (Ok ( newSession, UpdateReply.Success reply )) ->
            let
                newGlobals =
                    { globals | session = newSession, repo = Repo.setReply reply globals.repo }

                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.collapse

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), newGlobals )

        ReplyUpdated replyId (Ok ( newSession, UpdateReply.Invalid errors )) ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.setErrors errors

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), globals )

        ReplyUpdated replyId (Err Session.Expired) ->
            redirectToLogin globals model

        ReplyUpdated replyId (Err _) ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setNotSubmitting

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none ), globals )

        CreatePostReactionClicked ->
            let
                variables =
                    CreatePostReaction.variables spaceId model.postId

                cmd =
                    globals.session
                        |> CreatePostReaction.request variables
                        |> Task.attempt PostReactionCreated
            in
            ( ( model, cmd ), globals )

        PostReactionCreated (Ok ( newSession, CreatePostReaction.Success post )) ->
            let
                newGlobals =
                    { globals | repo = Repo.setPost post globals.repo, session = newSession }
            in
            ( ( model, Cmd.none ), newGlobals )

        PostReactionCreated (Err Session.Expired) ->
            redirectToLogin globals model

        PostReactionCreated _ ->
            ( ( model, Cmd.none ), globals )

        DeletePostReactionClicked ->
            let
                variables =
                    DeletePostReaction.variables spaceId model.postId

                cmd =
                    globals.session
                        |> DeletePostReaction.request variables
                        |> Task.attempt PostReactionDeleted
            in
            ( ( model, cmd ), globals )

        PostReactionDeleted (Ok ( newSession, DeletePostReaction.Success post )) ->
            let
                newGlobals =
                    { globals | repo = Repo.setPost post globals.repo, session = newSession }
            in
            ( ( model, Cmd.none ), newGlobals )

        PostReactionDeleted (Err Session.Expired) ->
            redirectToLogin globals model

        PostReactionDeleted _ ->
            ( ( model, Cmd.none ), globals )


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )


markVisibleRepliesAsViewed : Globals -> Id -> Model -> Cmd Msg
markVisibleRepliesAsViewed globals spaceId model =
    let
        ( replies, _ ) =
            visibleReplies globals.repo model.mode model.replyIds

        unviewedReplyIds =
            replies
                |> List.filter (\reply -> not (Reply.hasViewed reply))
                |> List.map Reply.id
    in
    if List.length unviewedReplyIds > 0 then
        globals.session
            |> RecordReplyViews.request spaceId unviewedReplyIds
            |> Task.attempt ReplyViewsRecorded

    else
        Cmd.none



-- EVENT HANDLERS


handleReplyCreated : Reply -> Model -> ( Model, Cmd Msg )
handleReplyCreated reply model =
    let
        cmd =
            case model.mode of
                FullPage ->
                    Scroll.toBottom Scroll.Document

                _ ->
                    Cmd.none
    in
    if Reply.postId reply == model.postId then
        ( { model | replyIds = Connection.append identity (Reply.id reply) model.replyIds }, cmd )

    else
        ( model, Cmd.none )


handleEditorEventReceived : Decode.Value -> Model -> Model
handleEditorEventReceived value model =
    case PostEditor.decodeEvent value of
        PostEditor.LocalDataFetched id body ->
            if id == PostEditor.getId model.replyComposer then
                let
                    newReplyComposer =
                        PostEditor.setBody body model.replyComposer
                in
                { model | replyComposer = newReplyComposer }

            else
                model

        PostEditor.Unknown ->
            model



-- VIEWS


view : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> List SpaceUser -> Model -> Html Msg
view repo space currentUser now spaceUsers model =
    case resolveData repo model of
        Just data ->
            resolvedView repo space currentUser now spaceUsers model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> List SpaceUser -> Model -> Data -> Html Msg
resolvedView repo space currentUser (( zone, posix ) as now) spaceUsers model data =
    div [ class "flex" ]
        [ div [ class "flex-no-shrink mr-4" ] [ Actor.avatar Avatar.Medium data.author ]
        , div [ class "flex-grow min-w-0 leading-semi-loose" ]
            [ div []
                [ postAuthorName space model.postId data.author
                , viewIf model.showGroups <|
                    groupsLabel space (Repo.getGroups (Post.groupIds data.post) repo)
                , a
                    [ Route.href <| Route.Post (Space.slug space) model.postId
                    , class "no-underline whitespace-no-wrap"
                    , rel "tooltip"
                    , title "Expand post"
                    ]
                    [ View.Helpers.time now ( zone, Post.postedAt data.post ) [ class "ml-3 text-sm text-dusty-blue" ] ]
                , viewIf (not (PostEditor.isExpanded model.postEditor) && Post.canEdit data.post) <|
                    div [ class "inline-block" ]
                        [ span [ class "mx-2 text-sm text-dusty-blue" ] [ text "·" ]
                        , button
                            [ class "text-sm text-dusty-blue"
                            , onClick ExpandPostEditor
                            ]
                            [ text "Edit" ]
                        ]
                ]
            , viewUnless (PostEditor.isExpanded model.postEditor) <|
                bodyView space model.mode data.post
            , viewIf (PostEditor.isExpanded model.postEditor) <|
                postEditorView (Space.id space) spaceUsers model.postEditor
            , div [ class "pb-2 flex items-start" ]
                [ postReactionButton data.post
                , viewIf (Post.state data.post == Post.Open) <|
                    button
                        [ class "flex mr-4 no-outline active:translate-y-1"
                        , style "margin-top" "4px"
                        , onClick ExpandReplyComposer
                        ]
                        [ Icons.comment ]
                ]
            , div [ class "relative" ]
                [ repliesView repo space data.post now model.replyIds model.mode spaceUsers model.replyEditors
                , replyComposerView (Space.id space) currentUser data.post spaceUsers model
                ]
            ]
        ]


checkableView : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> List SpaceUser -> Model -> Html Msg
checkableView repo space viewer now spaceUsers model =
    div [ class "flex" ]
        [ div [ class "mr-1 py-3 flex-0" ]
            [ label [ class "control checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , class "checkbox"
                    , checked model.isChecked
                    , onClick SelectionToggled
                    ]
                    []
                , span [ class "control-indicator border-dusty-blue" ] []
                ]
            ]
        , div [ class "flex-1" ]
            [ view repo space viewer now spaceUsers model
            ]
        ]



-- PRIVATE POST VIEW FUNCTIONS


postReactionButton : Post -> Html Msg
postReactionButton post =
    if Post.hasReacted post then
        button [ class "flex items-center mr-4 text-green font-bold text-sm no-outline active:translate-y-1", onClick DeletePostReactionClicked ]
            [ Icons.thumbs Icons.On
            , viewIf (Post.reactionCount post > 0) <|
                div [ class "ml-1" ] [ text <| String.fromInt (Post.reactionCount post) ]
            ]

    else
        button [ class "flex items-center mr-4 text-dusty-blue font-bold text-sm no-outline active:translate-y-1", onClick CreatePostReactionClicked ]
            [ Icons.thumbs Icons.Off
            , viewIf (Post.reactionCount post > 0) <|
                div [ class "ml-1" ] [ text <| String.fromInt (Post.reactionCount post) ]
            ]


postAuthorName : Space -> Id -> Actor -> Html Msg
postAuthorName space postId author =
    let
        route =
            case author of
                Actor.User user ->
                    Route.SpaceUser (Route.SpaceUser.init (Space.slug space) (SpaceUser.id user))

                _ ->
                    Route.Post (Space.slug space) postId
    in
    a
        [ Route.href route
        , class "no-underline text-dusty-blue-darkest whitespace-no-wrap"
        , rel "tooltip"
        , title "Expand post"
        ]
        [ span [ class "font-headline font-bold" ] [ text <| Actor.displayName author ] ]


groupsLabel : Space -> List Group -> Html Msg
groupsLabel space groups =
    case groups of
        [ group ] ->
            span [ class "ml-3 text-sm text-dusty-blue" ]
                [ a
                    [ Route.href (Route.Group (Route.Group.init (Space.slug space) (Group.id group)))
                    , class "no-underline text-dusty-blue font-bold whitespace-no-wrap"
                    ]
                    [ text (Group.name group) ]
                ]

        _ ->
            text ""


bodyView : Space -> Mode -> Post -> Html Msg
bodyView space mode post =
    clickToExpandIf (mode == Feed)
        [ div [ class "markdown mb-2" ] [ RenderedHtml.node (Post.bodyHtml post) ]
        , staticFilesView (Post.files post)
        ]


postEditorView : Id -> List SpaceUser -> PostEditor -> Html Msg
postEditorView spaceId spaceUsers editor =
    let
        config =
            { editor = editor
            , spaceId = spaceId
            , spaceUsers = spaceUsers
            , onFileAdded = PostEditorFileAdded
            , onFileUploadProgress = PostEditorFileUploadProgress
            , onFileUploaded = PostEditorFileUploaded
            , onFileUploadError = PostEditorFileUploadError
            , classList = [ ( "tribute-pin-t", True ) ]
            }
    in
    PostEditor.wrapper config
        [ label [ class "composer my-2 p-3" ]
            [ textarea
                [ id (PostEditor.getTextareaId editor)
                , class "w-full no-outline text-dusty-blue-darkest bg-transparent resize-none leading-normal"
                , placeholder "Edit post..."
                , onInput PostEditorBodyChanged
                , readonly (PostEditor.isSubmitting editor)
                , value (PostEditor.getBody editor)
                , onKeydown preventDefault
                    [ ( [ Meta ], enter, \event -> PostEditorSubmitted )
                    ]
                ]
                []
            , ValidationError.prefixedErrorView "body" "Body" (PostEditor.getErrors editor)
            , PostEditor.filesView editor
            , div [ class "flex justify-end" ]
                [ button
                    [ class "mr-2 btn btn-grey-outline btn-sm"
                    , onClick CollapsePostEditor
                    ]
                    [ text "Cancel" ]
                , button
                    [ class "btn btn-blue btn-sm"
                    , onClick PostEditorSubmitted
                    , disabled (PostEditor.isUnsubmittable editor)
                    ]
                    [ text "Update post" ]
                ]
            ]
        ]



-- PRIVATE REPLY VIEW FUNCTIONS


repliesView : Repo -> Space -> Post -> ( Zone, Posix ) -> Connection String -> Mode -> List SpaceUser -> ReplyEditors -> Html Msg
repliesView repo space post now replyIds mode spaceUsers editors =
    let
        ( replies, hasPreviousPage ) =
            visibleReplies repo mode replyIds

        actionButton =
            case mode of
                Feed ->
                    a
                        [ Route.href (Route.Post (Space.slug space) (Post.id post))
                        , class "mb-2 text-dusty-blue no-underline whitespace-no-wrap"
                        ]
                        [ text "Show more..." ]

                FullPage ->
                    button
                        [ class "mb-2 text-dusty-blue no-underline whitespace-no-wrap"
                        , onClick PreviousRepliesRequested
                        ]
                        [ text "Load more..." ]
    in
    viewUnless (Connection.isEmptyAndExpanded replyIds) <|
        div []
            [ viewIf hasPreviousPage actionButton
            , div [] (List.map (replyView repo now space post mode editors spaceUsers) replies)
            ]


replyView : Repo -> ( Zone, Posix ) -> Space -> Post -> Mode -> ReplyEditors -> List SpaceUser -> Reply -> Html Msg
replyView repo (( zone, posix ) as now) space post mode editors spaceUsers reply =
    let
        replyId =
            Reply.id reply

        editor =
            getReplyEditor replyId editors
    in
    case Repo.getActor (Reply.authorId reply) repo of
        Just author ->
            div
                [ id (replyNodeId replyId)
                , classList [ ( "flex mt-3 relative", True ) ]
                ]
                [ viewUnless (Reply.hasViewed reply) <|
                    div [ class "mr-2 -ml-3 w-1 rounded pin-t pin-b bg-turquoise flex-no-shrink" ] []
                , div [ class "flex-no-shrink mr-3" ] [ Actor.avatar Avatar.Small author ]
                , div [ class "flex-grow leading-semi-loose" ]
                    [ clickToExpandIf (mode == Feed)
                        [ replyAuthorName space author
                        , View.Helpers.time now ( zone, Reply.postedAt reply ) [ class "ml-3 text-sm text-dusty-blue whitespace-no-wrap" ]
                        , viewIf (not (PostEditor.isExpanded editor) && Reply.canEdit reply) <|
                            div [ class "inline-block" ]
                                [ span [ class "mx-2 text-sm text-dusty-blue" ] [ text "·" ]
                                , button
                                    [ class "text-sm text-dusty-blue"
                                    , onClick (ExpandReplyEditor replyId)
                                    ]
                                    [ text "Edit" ]
                                ]
                        ]
                    , viewUnless (PostEditor.isExpanded editor) <|
                        clickToExpandIf (mode == Feed)
                            [ div [ class "markdown mb-2" ]
                                [ RenderedHtml.node (Reply.bodyHtml reply)
                                ]
                            , staticFilesView (Reply.files reply)
                            ]
                    , viewIf (PostEditor.isExpanded editor) <|
                        replyEditorView (Space.id space) replyId spaceUsers editor
                    ]
                ]

        Nothing ->
            -- The author was not in the repo as expected, so we can't display the reply
            text ""


replyAuthorName : Space -> Actor -> Html Msg
replyAuthorName space author =
    case author of
        Actor.User user ->
            a
                [ Route.href <| Route.SpaceUser (Route.SpaceUser.init (Space.slug space) (SpaceUser.id user))
                , class "font-headline font-bold whitespace-no-wrap text-dusty-blue-darkest no-underline"
                ]
                [ text <| Actor.displayName author ]

        _ ->
            span [ class "font-headline font-bold whitespace-no-wrap" ] [ text <| Actor.displayName author ]


replyEditorView : Id -> Id -> List SpaceUser -> PostEditor -> Html Msg
replyEditorView spaceId replyId spaceUsers editor =
    let
        config =
            { editor = editor
            , spaceId = spaceId
            , spaceUsers = spaceUsers
            , onFileAdded = ReplyEditorFileAdded replyId
            , onFileUploadProgress = ReplyEditorFileUploadProgress replyId
            , onFileUploaded = ReplyEditorFileUploaded replyId
            , onFileUploadError = ReplyEditorFileUploadError replyId
            , classList = [ ( "tribute-pin-t", True ) ]
            }
    in
    PostEditor.wrapper config
        [ label [ class "composer my-2 p-3" ]
            [ textarea
                [ id (PostEditor.getTextareaId editor)
                , class "w-full no-outline text-dusty-blue-darkest bg-transparent resize-none leading-normal"
                , placeholder "Edit reply..."
                , onInput (ReplyEditorBodyChanged replyId)
                , readonly (PostEditor.isSubmitting editor)
                , value (PostEditor.getBody editor)
                , onKeydown preventDefault
                    [ ( [ Meta ], enter, \event -> ReplyEditorSubmitted replyId )
                    ]
                ]
                []
            , ValidationError.prefixedErrorView "body" "Body" (PostEditor.getErrors editor)
            , PostEditor.filesView editor
            , div [ class "flex justify-end" ]
                [ button
                    [ class "mr-2 btn btn-grey-outline btn-sm"
                    , onClick (CollapseReplyEditor replyId)
                    ]
                    [ text "Cancel" ]
                , button
                    [ class "btn btn-blue btn-sm"
                    , onClick (ReplyEditorSubmitted replyId)
                    , disabled (PostEditor.isUnsubmittable editor)
                    ]
                    [ text "Update reply" ]
                ]
            ]
        ]


replyComposerView : Id -> SpaceUser -> Post -> List SpaceUser -> Model -> Html Msg
replyComposerView spaceId currentUser post spaceUsers model =
    if Post.state post == Post.Closed then
        clickToExpandIf (model.mode == Feed)
            [ div [ class "flex items-center my-3" ]
                [ div [ class "flex-no-shrink mr-3" ] [ Icons.closedAvatar ]
                , div [ class "flex-grow leading-semi-loose" ]
                    [ span [ class "mr-3 text-dusty-blue-dark" ] [ text "This post is resolved" ]
                    , viewIf (Post.inboxState post == Post.Read || Post.inboxState post == Post.Unread) <|
                        button
                            [ class "btn btn-grey-outline btn-sm"
                            , onClick DismissClicked
                            ]
                            [ text "Dismiss from my inbox" ]
                    ]
                ]
            ]

    else if PostEditor.isExpanded model.replyComposer then
        expandedReplyComposerView spaceId currentUser post spaceUsers model.replyComposer

    else
        viewUnless (Connection.isEmpty model.replyIds) <|
            replyPromptView currentUser


expandedReplyComposerView : Id -> SpaceUser -> Post -> List SpaceUser -> PostEditor -> Html Msg
expandedReplyComposerView spaceId currentUser post spaceUsers editor =
    let
        config =
            { editor = editor
            , spaceId = spaceId
            , spaceUsers = spaceUsers
            , onFileAdded = NewReplyFileAdded
            , onFileUploadProgress = NewReplyFileUploadProgress
            , onFileUploaded = NewReplyFileUploaded
            , onFileUploadError = NewReplyFileUploadError
            , classList = [ ( "tribute-pin-t", True ) ]
            }
    in
    div [ class "-ml-3 py-3 sticky pin-b bg-white" ]
        [ PostEditor.wrapper config
            [ div [ class "composer p-0" ]
                [ viewIf (Post.inboxState post == Post.Unread || Post.inboxState post == Post.Read) <|
                    div [ class "flex rounded-t-lg bg-turquoise border-b border-white px-3 py-2" ]
                        [ span [ class "flex-grow mr-3 text-sm text-white font-bold" ]
                            [ span [ class "mr-2 inline-block" ] [ Icons.inboxWhite ]
                            , text "This post is currently in your inbox."
                            ]
                        , button
                            [ class "flex-no-shrink btn btn-xs btn-turquoise-inverse"
                            , onClick DismissClicked
                            ]
                            [ text "Dismiss from my inbox" ]
                        ]
                , label [ class "flex p-3" ]
                    [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Small currentUser ]
                    , div [ class "flex-grow" ]
                        [ textarea
                            [ id (PostEditor.getTextareaId editor)
                            , class "p-1 w-full h-10 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                            , placeholder "Write a reply..."
                            , onInput NewReplyBodyChanged
                            , onKeydown preventDefault
                                [ ( [ Meta ], enter, \event -> NewReplySubmit )
                                , ( [], esc, \event -> NewReplyEscaped )
                                ]
                            , onBlur NewReplyBlurred
                            , value (PostEditor.getBody editor)
                            , readonly (PostEditor.isSubmitting editor)
                            ]
                            []
                        , PostEditor.filesView editor
                        , div [ class "flex items-baseline justify-end" ]
                            [ button
                                [ class "btn btn-blue btn-sm"
                                , onClick NewReplySubmit
                                , disabled (PostEditor.isUnsubmittable editor)
                                ]
                                [ text "Send" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


replyPromptView : SpaceUser -> Html Msg
replyPromptView currentUser =
    button [ class "flex my-3 items-center", onClick ExpandReplyComposer ]
        [ div [ class "flex-no-shrink mr-3" ] [ SpaceUser.avatar Avatar.Small currentUser ]
        , div [ class "flex-grow leading-semi-loose text-dusty-blue" ]
            [ text "Write a reply..."
            ]
        ]


staticFilesView : List File -> Html msg
staticFilesView files =
    viewUnless (List.isEmpty files) <|
        div [ class "flex flex-wrap pb-2" ] <|
            List.map staticFileView files


staticFileView : File -> Html msg
staticFileView file =
    case File.getState file of
        File.Uploaded id url ->
            a
                [ href url
                , target "_blank"
                , class "flex flex-none items-center mr-4 pb-1 no-underline text-dusty-blue hover:text-blue"
                , rel "tooltip"
                , title "Download file"
                ]
                [ div [ class "mr-2" ] [ File.icon Color.DustyBlue file ]
                , div [ class "text-sm font-bold truncate" ] [ text <| "Download " ++ File.getName file ]
                ]

        _ ->
            text ""



-- UTILS


replyNodeId : String -> String
replyNodeId replyId =
    "reply-" ++ replyId


replyComposerId : String -> String
replyComposerId postId =
    "reply-composer-" ++ postId


visibleReplies : Repo -> Mode -> Connection Id -> ( List Reply, Bool )
visibleReplies repo mode replyIds =
    case mode of
        Feed ->
            let
                { nodes, hasPreviousPage } =
                    Connection.last 10 replyIds
            in
            ( Repo.getReplies nodes repo, hasPreviousPage )

        FullPage ->
            let
                replies =
                    Repo.getReplies (Connection.toList replyIds) repo

                hasPreviousPage =
                    Connection.hasPreviousPage replyIds
            in
            ( replies, hasPreviousPage )


getReplyEditor : Id -> ReplyEditors -> PostEditor
getReplyEditor replyId editors =
    Dict.get replyId editors
        |> Maybe.withDefault (PostEditor.init replyId)


clickToExpandIf : Bool -> List (Html Msg) -> Html Msg
clickToExpandIf truth children =
    if truth then
        div [ class "cursor-pointer select-none", onPassiveClick ClickedToExpand ] children

    else
        div [] children
