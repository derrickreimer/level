module Component.Post exposing (Model, Msg(..), ViewConfig, expandReplyComposer, handleEditorEventReceived, handleReplyCreated, init, markVisibleRepliesAsViewed, postNodeId, setup, teardown, update, view)

import Actor exposing (Actor)
import Avatar exposing (personAvatar)
import Browser.Navigation as Nav
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
import Mutation.ClosePost as ClosePost
import Mutation.CreatePostReaction as CreatePostReaction
import Mutation.CreateReply as CreateReply
import Mutation.CreateReplyReaction as CreateReplyReaction
import Mutation.DeletePost as DeletePost
import Mutation.DeletePostReaction as DeletePostReaction
import Mutation.DeleteReply as DeleteReply
import Mutation.DeleteReplyReaction as DeleteReplyReaction
import Mutation.DismissPosts as DismissPosts
import Mutation.MarkAsRead as MarkAsRead
import Mutation.RecordReplyViews as RecordReplyViews
import Mutation.ReopenPost as ReopenPost
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
    , spaceId : String
    , postId : Id
    , replyIds : Connection Id
    , replyComposer : PostEditor
    , postEditor : PostEditor
    , replyEditors : ReplyEditors
    , isChecked : Bool
    }


type alias Data =
    { post : Post
    , author : Actor
    , reactors : List SpaceUser
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
            Maybe.map3 Data
                (Just post)
                (Repo.getActor (Post.authorId post) repo)
                (Just <| Repo.getSpaceUsers (Post.reactorIds post) repo)

        Nothing ->
            Nothing



-- LIFECYCLE


init : Id -> Id -> Connection Id -> Model
init spaceId postId replyIds =
    Model
        postId
        spaceId
        postId
        replyIds
        (PostEditor.init postId)
        (PostEditor.init postId)
        Dict.empty
        False


setup : Globals -> Model -> Cmd Msg
setup globals model =
    Cmd.batch
        [ PostSubscription.subscribe model.postId
        , markVisibleRepliesAsViewed globals model
        ]


teardown : Globals -> Model -> Cmd Msg
teardown globals model =
    PostSubscription.unsubscribe model.postId



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
    | NewReplyAndCloseSubmit
    | NewReplyEscaped
    | NewReplySubmitted (Result Session.Error ( Session, CreateReply.Response ))
    | PreviousRepliesRequested
    | PreviousRepliesFetched (Result Session.Error ( Session, Query.Replies.Response ))
    | ReplyViewsRecorded (Result Session.Error ( Session, RecordReplyViews.Response ))
    | SelectionToggled
    | DismissClicked
    | Dismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | MoveToInboxClicked
    | PostMovedToInbox (Result Session.Error ( Session, MarkAsRead.Response ))
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
    | CreateReplyReactionClicked Id
    | DeleteReplyReactionClicked Id
    | ReplyReactionCreated Id (Result Session.Error ( Session, CreateReplyReaction.Response ))
    | ReplyReactionDeleted Id (Result Session.Error ( Session, DeleteReplyReaction.Response ))
    | ClosePostClicked
    | ReopenPostClicked
    | PostClosed (Result Session.Error ( Session, ClosePost.Response ))
    | PostReopened (Result Session.Error ( Session, ReopenPost.Response ))
    | DeletePostClicked
    | PostDeleted (Result Session.Error ( Session, DeletePost.Response ))
    | DeleteReplyClicked Id
    | ReplyDeleted Id (Result Session.Error ( Session, DeleteReply.Response ))
    | InternalLinkClicked String


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            noCmd globals model

        ExpandReplyComposer ->
            expandReplyComposer globals model

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
                        |> CreateReply.request model.spaceId model.postId body (PostEditor.getUploadIds model.replyComposer)
                        |> Task.attempt NewReplySubmitted
            in
            ( ( newModel, cmd ), globals )

        NewReplyAndCloseSubmit ->
            let
                newModel =
                    { model | replyComposer = PostEditor.setToSubmitting model.replyComposer }

                body =
                    PostEditor.getBody model.replyComposer

                replyCmd =
                    globals.session
                        |> CreateReply.request model.spaceId model.postId body (PostEditor.getUploadIds model.replyComposer)
                        |> Task.attempt NewReplySubmitted

                closeCmd =
                    globals.session
                        |> ClosePost.request model.spaceId model.postId
                        |> Task.attempt PostClosed
            in
            ( ( newModel, Cmd.batch [ replyCmd, closeCmd ] ), globals )

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
            if PostEditor.getBody model.replyComposer == "" then
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
                                |> Query.Replies.request model.spaceId model.postId cursor 10
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
                    markVisibleRepliesAsViewed newGlobals newModel
            in
            ( ( newModel, Cmd.batch [ viewCmd ] ), newGlobals )

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
              , markVisibleRepliesAsViewed globals model
              )
            , globals
            )

        DismissClicked ->
            let
                cmd =
                    globals.session
                        |> DismissPosts.request model.spaceId [ model.postId ]
                        |> Task.attempt Dismissed
            in
            ( ( model, cmd ), globals )

        Dismissed (Ok ( newSession, _ )) ->
            ( ( model, Cmd.none )
            , { globals
                | session = newSession
                , flash = Flash.set Flash.Notice "Dismissed from inbox" 3000 globals.flash
              }
            )

        Dismissed (Err Session.Expired) ->
            redirectToLogin globals model

        Dismissed (Err _) ->
            noCmd globals model

        MoveToInboxClicked ->
            let
                cmd =
                    globals.session
                        |> MarkAsRead.request model.spaceId [ model.postId ]
                        |> Task.attempt PostMovedToInbox
            in
            ( ( model, cmd ), globals )

        PostMovedToInbox (Ok ( newSession, _ )) ->
            ( ( model, Cmd.none )
            , { globals
                | session = newSession
                , flash = Flash.set Flash.Notice "Moved to inbox" 3000 globals.flash
              }
            )

        PostMovedToInbox (Err Session.Expired) ->
            redirectToLogin globals model

        PostMovedToInbox (Err _) ->
            noCmd globals model

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
                        |> UpdatePost.request model.spaceId model.postId (PostEditor.getBody model.postEditor)
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
                        |> UpdateReply.request model.spaceId replyId (PostEditor.getBody replyEditor)
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
                    CreatePostReaction.variables model.spaceId model.postId

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
                    DeletePostReaction.variables model.spaceId model.postId

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

        CreateReplyReactionClicked replyId ->
            let
                variables =
                    CreateReplyReaction.variables model.spaceId model.postId replyId

                cmd =
                    globals.session
                        |> CreateReplyReaction.request variables
                        |> Task.attempt (ReplyReactionCreated replyId)
            in
            ( ( model, cmd ), globals )

        ReplyReactionCreated _ (Ok ( newSession, CreateReplyReaction.Success reply )) ->
            let
                newGlobals =
                    { globals | repo = Repo.setReply reply globals.repo, session = newSession }
            in
            ( ( model, Cmd.none ), newGlobals )

        ReplyReactionCreated _ (Err Session.Expired) ->
            redirectToLogin globals model

        ReplyReactionCreated _ _ ->
            ( ( model, Cmd.none ), globals )

        DeleteReplyReactionClicked replyId ->
            let
                variables =
                    DeleteReplyReaction.variables model.spaceId model.postId replyId

                cmd =
                    globals.session
                        |> DeleteReplyReaction.request variables
                        |> Task.attempt (ReplyReactionDeleted replyId)
            in
            ( ( model, cmd ), globals )

        ReplyReactionDeleted _ (Ok ( newSession, DeleteReplyReaction.Success reply )) ->
            let
                newGlobals =
                    { globals | repo = Repo.setReply reply globals.repo, session = newSession }
            in
            ( ( model, Cmd.none ), newGlobals )

        ReplyReactionDeleted _ (Err Session.Expired) ->
            redirectToLogin globals model

        ReplyReactionDeleted _ _ ->
            ( ( model, Cmd.none ), globals )

        ClosePostClicked ->
            let
                cmd =
                    globals.session
                        |> ClosePost.request model.spaceId model.postId
                        |> Task.attempt PostClosed
            in
            ( ( { model | replyComposer = PostEditor.setToSubmitting model.replyComposer }, cmd ), globals )

        ReopenPostClicked ->
            let
                cmd =
                    globals.session
                        |> ReopenPost.request model.spaceId model.postId
                        |> Task.attempt PostReopened
            in
            ( ( { model | replyComposer = PostEditor.setToSubmitting model.replyComposer }, cmd ), globals )

        DeletePostClicked ->
            let
                cmd =
                    globals.session
                        |> DeletePost.request (DeletePost.variables model.spaceId model.postId)
                        |> Task.attempt PostDeleted
            in
            ( ( { model | postEditor = PostEditor.setToSubmitting model.postEditor }, cmd ), globals )

        PostClosed (Ok ( newSession, ClosePost.Success post )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setPost post
            in
            ( ( { model | replyComposer = PostEditor.setNotSubmitting model.replyComposer }, Cmd.none )
            , { globals | repo = newRepo, session = newSession }
            )

        PostClosed (Ok ( newSession, ClosePost.Invalid errors )) ->
            ( ( { model | replyComposer = PostEditor.setNotSubmitting model.replyComposer }, Cmd.none )
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

                newReplyComposer =
                    model.replyComposer
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.expand

                cmd =
                    setFocus (PostEditor.getTextareaId newReplyComposer) NoOp
            in
            ( ( { model | replyComposer = newReplyComposer }, cmd )
            , { globals | repo = newRepo, session = newSession }
            )

        PostReopened (Ok ( newSession, ReopenPost.Invalid errors )) ->
            ( ( { model | replyComposer = PostEditor.setNotSubmitting model.replyComposer }, Cmd.none )
            , { globals | session = newSession }
            )

        PostReopened (Err Session.Expired) ->
            redirectToLogin globals model

        PostReopened (Err _) ->
            noCmd globals model

        PostDeleted (Ok ( newSession, DeletePost.Success post )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setPost post

                newPostEditor =
                    model.postEditor
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.collapse
            in
            ( ( { model | postEditor = newPostEditor }, Cmd.none )
            , { globals | repo = newRepo, session = newSession }
            )

        PostDeleted (Ok ( newSession, DeletePost.Invalid errors )) ->
            ( ( { model | postEditor = PostEditor.setNotSubmitting model.postEditor }, Cmd.none )
            , { globals | session = newSession }
            )

        PostDeleted (Err Session.Expired) ->
            redirectToLogin globals model

        PostDeleted (Err _) ->
            noCmd globals model

        DeleteReplyClicked replyId ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setToSubmitting

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor

                cmd =
                    globals.session
                        |> DeleteReply.request (DeleteReply.variables model.spaceId replyId)
                        |> Task.attempt (ReplyDeleted replyId)
            in
            ( ( { model | replyEditors = newReplyEditors }, cmd ), globals )

        ReplyDeleted _ (Ok ( newSession, DeleteReply.Success reply )) ->
            ( ( model, Cmd.none ), { globals | session = newSession } )

        ReplyDeleted replyId (Ok ( newSession, DeleteReply.Invalid _ )) ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setNotSubmitting

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none )
            , { globals | session = newSession }
            )

        ReplyDeleted _ (Err Session.Expired) ->
            redirectToLogin globals model

        ReplyDeleted replyId (Err _) ->
            let
                newReplyEditor =
                    model.replyEditors
                        |> getReplyEditor replyId
                        |> PostEditor.setNotSubmitting

                newReplyEditors =
                    model.replyEditors
                        |> Dict.insert replyId newReplyEditor
            in
            ( ( { model | replyEditors = newReplyEditors }, Cmd.none )
            , globals
            )

        InternalLinkClicked pathname ->
            ( ( model, Nav.pushUrl globals.navKey pathname ), globals )


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )


markVisibleRepliesAsViewed : Globals -> Model -> Cmd Msg
markVisibleRepliesAsViewed globals model =
    let
        ( replies, _ ) =
            visibleReplies globals.repo model.replyIds

        unviewedReplyIds =
            replies
                |> List.filter (\reply -> not (Reply.hasViewed reply))
                |> List.map Reply.id
    in
    if List.length unviewedReplyIds > 0 then
        globals.session
            |> RecordReplyViews.request model.spaceId unviewedReplyIds
            |> Task.attempt ReplyViewsRecorded

    else
        Cmd.none


expandReplyComposer : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
expandReplyComposer globals model =
    let
        cmd =
            Cmd.batch
                [ setFocus (PostEditor.getTextareaId model.replyComposer) NoOp
                , markVisibleRepliesAsViewed globals model
                ]

        newModel =
            { model | replyComposer = PostEditor.expand model.replyComposer }
    in
    ( ( newModel, cmd ), globals )



-- EVENT HANDLERS


handleReplyCreated : Reply -> Model -> ( Model, Cmd Msg )
handleReplyCreated reply model =
    if Reply.postId reply == model.postId then
        ( { model | replyIds = Connection.append identity (Reply.id reply) model.replyIds }, Cmd.none )

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


type alias ViewConfig =
    { globals : Globals
    , space : Space
    , currentUser : SpaceUser
    , now : ( Zone, Posix )
    , spaceUsers : List SpaceUser
    , groups : List Group
    , showGroups : Bool
    }


view : ViewConfig -> Model -> Html Msg
view config model =
    case resolveData config.globals.repo model of
        Just data ->
            resolvedView config model data

        Nothing ->
            text "Something went wrong."


resolvedView : ViewConfig -> Model -> Data -> Html Msg
resolvedView config model data =
    let
        ( zone, posix ) =
            config.now
    in
    div [ id (postNodeId model.postId), class "flex" ]
        [ div [ class "flex-no-shrink mr-4" ] [ Actor.avatar Avatar.Medium data.author ]
        , div [ class "flex-grow min-w-0 leading-normal" ]
            [ div [ class "pb-1/2 flex items-center flex-wrap" ]
                [ div []
                    [ postAuthorName config.space model.postId data.author

                    -- , span [ class "mx-1 text-dusty-blue" ] [ text "·" ]
                    , a
                        [ Route.href <| Route.Post (Space.slug config.space) model.postId
                        , class "no-underline whitespace-no-wrap"
                        , rel "tooltip"
                        , title "Expand post"
                        ]
                        [ View.Helpers.time config.now ( zone, Post.postedAt data.post ) [ class "mr-3 text-sm text-dusty-blue" ] ]
                    , viewIf (not (PostEditor.isExpanded model.postEditor) && Post.canEdit data.post) <|
                        button
                            [ class "mr-3 text-sm text-dusty-blue"
                            , onClick ExpandPostEditor
                            ]
                            [ text "Edit" ]
                    ]
                , inboxButton data.post
                ]
            , viewIf config.showGroups <|
                groupsLabel config.space (Repo.getGroups (Post.groupIds data.post) config.globals.repo)
            , viewUnless (PostEditor.isExpanded model.postEditor) <|
                bodyView config.space data.post
            , viewIf (PostEditor.isExpanded model.postEditor) <|
                postEditorView config model.postEditor
            , div [ class "pb-2 flex items-start" ]
                [ postReactionButton data.post data.reactors
                , replyButtonView config model data
                ]
            , div [ class "relative" ]
                [ repliesView config model data
                , replyComposerView config model data
                ]
            ]
        ]



-- PRIVATE POST VIEW FUNCTIONS


inboxButton : Post -> Html Msg
inboxButton post =
    let
        addButton =
            button
                [ class "flex tooltip tooltip-bottom no-outline"
                , onClick MoveToInboxClicked
                , attribute "data-tooltip" "Move to inbox"
                ]
                [ Icons.inbox Icons.Off
                ]

        removeButton =
            button
                [ class "flex tooltip tooltip-bottom no-outline text-sm text-green font-bold"
                , onClick DismissClicked
                , attribute "data-tooltip" "Dismiss from inbox"
                ]
                [ span [ class "inline-block" ] [ Icons.inbox Icons.On ]
                ]
    in
    case Post.inboxState post of
        Post.Excluded ->
            addButton

        Post.Dismissed ->
            addButton

        Post.Read ->
            removeButton

        Post.Unread ->
            removeButton


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
        , class "no-underline whitespace-no-wrap"
        ]
        [ span [ class "font-bold text-dusty-blue-darkest mr-2" ] [ text <| Actor.displayName author ]
        , span [ class "ml-2 text-dusty-blue hidden" ] [ text <| "@" ++ Actor.handle author ]
        ]


groupsLabel : Space -> List Group -> Html Msg
groupsLabel space groups =
    let
        groupLink group =
            a
                [ Route.href (Route.Group (Route.Group.init (Space.slug space) (Group.name group)))
                , class "mr-1 no-underline text-dusty-blue-dark whitespace-no-wrap"
                ]
                [ text ("#" ++ Group.name group) ]

        groupLinks =
            List.map groupLink groups
    in
    if List.isEmpty groups then
        text ""

    else
        div [ class "pb-1 mr-3 text-base text-dusty-blue" ]
            [ text ""
            , span [] groupLinks
            ]


bodyView : Space -> Post -> Html Msg
bodyView space post =
    div []
        [ div [ class "markdown pb-3/2" ]
            [ RenderedHtml.node
                { html = Post.bodyHtml post
                , onInternalLinkClicked = InternalLinkClicked
                }
            ]
        , staticFilesView (Post.files post)
        ]


postEditorView : ViewConfig -> PostEditor -> Html Msg
postEditorView viewConfig editor =
    let
        config =
            { editor = editor
            , spaceId = Space.id viewConfig.space
            , spaceUsers = viewConfig.spaceUsers
            , groups = viewConfig.groups
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
            , div [ class "flex" ]
                [ button
                    [ class "mr-2 btn btn-grey-outline btn-sm"
                    , onClick DeletePostClicked
                    ]
                    [ text "Delete post" ]
                , div [ class "flex-grow flex justify-end" ]
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
        ]



-- PRIVATE REPLY VIEW FUNCTIONS


repliesView : ViewConfig -> Model -> Data -> Html Msg
repliesView config model data =
    let
        ( replies, hasPreviousPage ) =
            visibleReplies config.globals.repo model.replyIds
    in
    viewUnless (Connection.isEmptyAndExpanded model.replyIds) <|
        div []
            [ viewIf hasPreviousPage <|
                button
                    [ class "flex items-center mt-2 mb-4 text-dusty-blue no-underline whitespace-no-wrap"
                    , onClick PreviousRepliesRequested
                    ]
                    [ text "Load more..."
                    ]
            , div [] (List.map (replyView config model data) replies)
            ]


replyView : ViewConfig -> Model -> Data -> Reply -> Html Msg
replyView config model data reply =
    let
        ( zone, _ ) =
            config.now

        replyId =
            Reply.id reply

        reactors =
            Repo.getSpaceUsers (Reply.reactorIds reply) config.globals.repo

        editor =
            getReplyEditor replyId model.replyEditors
    in
    case Repo.getActor (Reply.authorId reply) config.globals.repo of
        Just author ->
            div
                [ id (replyNodeId replyId)
                , classList [ ( "flex mt-3 relative", True ) ]
                ]
                [ viewUnless (Reply.hasViewed reply) <|
                    div [ class "mr-2 -ml-3 w-1 h-9 rounded pin-t bg-orange flex-no-shrink" ] []
                , div [ class "flex-no-shrink mr-3" ] [ Actor.avatar Avatar.Small author ]
                , div [ class "flex-grow leading-normal" ]
                    [ div [ class "pb-1/2" ]
                        [ replyAuthorName config.space author

                        -- , span [ class "mx-1 text-dusty-blue text-sm" ] [ text "·" ]
                        , View.Helpers.time config.now ( zone, Reply.postedAt reply ) [ class "mr-3 text-sm text-dusty-blue whitespace-no-wrap" ]
                        , viewIf (not (PostEditor.isExpanded editor) && Reply.canEdit reply) <|
                            button
                                [ class "mr-3 text-sm text-dusty-blue"
                                , onClick (ExpandReplyEditor replyId)
                                ]
                                [ text "Edit" ]
                        , viewIf (Reply.reactionCount reply == 0) <|
                            button
                                [ class "relative border-dusty-blue rounded"
                                , style "bottom" "-2px"
                                , onClick <| CreateReplyReactionClicked (Reply.id reply)
                                ]
                                [ Icons.thumbsSmall ]
                        ]
                    , viewUnless (PostEditor.isExpanded editor) <|
                        div []
                            [ div [ class "markdown pb-3/2" ]
                                [ RenderedHtml.node
                                    { html = Reply.bodyHtml reply
                                    , onInternalLinkClicked = InternalLinkClicked
                                    }
                                ]
                            , staticFilesView (Reply.files reply)
                            ]
                    , viewIf (PostEditor.isExpanded editor) <| replyEditorView config replyId editor
                    , viewIf (Reply.reactionCount reply > 0) <|
                        div [ class "pb-2 flex items-start" ] [ replyReactionButton reply reactors ]
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
                , class "whitespace-no-wrap no-underline"
                ]
                [ span [ class "font-bold text-dusty-blue-darkest mr-2" ] [ text <| Actor.displayName author ]
                , span [ class "ml-2 text-dusty-blue hidden" ] [ text <| "@" ++ Actor.handle author ]
                ]

        _ ->
            span [ class "whitespace-no-wrap" ]
                [ span [ class "font-bold text-dusty-blue-darkest mr-2" ] [ text <| Actor.displayName author ]
                , span [ class "ml-2 text-dusty-blue hidden" ] [ text <| "@" ++ Actor.handle author ]
                ]


replyEditorView : ViewConfig -> Id -> PostEditor -> Html Msg
replyEditorView viewConfig replyId editor =
    let
        config =
            { editor = editor
            , spaceId = Space.id viewConfig.space
            , spaceUsers = viewConfig.spaceUsers
            , groups = viewConfig.groups
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
            , div [ class "flex" ]
                [ button
                    [ class "mr-2 btn btn-grey-outline btn-sm"
                    , onClick (DeleteReplyClicked replyId)
                    ]
                    [ text "Delete reply" ]
                , div [ class "flex-grow flex justify-end" ]
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
        ]


replyComposerView : ViewConfig -> Model -> Data -> Html Msg
replyComposerView viewConfig model data =
    let
        post =
            data.post
    in
    if Post.state post == Post.Closed then
        div [ class "flex flex-wrap items-center my-3" ]
            [ div [ class "flex-no-shrink mr-3" ] [ Icons.closedAvatar ]
            , div [ class "flex-no-shrink mr-3 text-base text-green font-bold" ] [ text "Resolved" ]
            , div [ class "flex-no-shrink leading-semi-loose" ]
                [ button
                    [ class "mr-2 my-1 btn btn-grey-outline btn-sm"
                    , onClick ReopenPostClicked
                    ]
                    [ text "Reopen" ]
                , viewIf (Post.inboxState post == Post.Read || Post.inboxState post == Post.Unread) <|
                    button
                        [ class "my-1 btn btn-grey-outline btn-sm"
                        , onClick DismissClicked
                        ]
                        [ text "Dismiss from inbox" ]
                ]
            ]

    else if PostEditor.isExpanded model.replyComposer then
        expandedReplyComposerView viewConfig model.replyComposer

    else
        replyPromptView viewConfig model data


expandedReplyComposerView : ViewConfig -> PostEditor -> Html Msg
expandedReplyComposerView viewConfig editor =
    let
        config =
            { editor = editor
            , spaceId = Space.id viewConfig.space
            , spaceUsers = viewConfig.spaceUsers
            , groups = viewConfig.groups
            , onFileAdded = NewReplyFileAdded
            , onFileUploadProgress = NewReplyFileUploadProgress
            , onFileUploaded = NewReplyFileUploaded
            , onFileUploadError = NewReplyFileUploadError
            , classList = [ ( "tribute-pin-t", True ) ]
            }
    in
    div [ class "-ml-3 pt-3 sticky pin-b bg-white" ]
        [ PostEditor.wrapper config
            [ div [ class "composer p-0" ]
                [ label [ class "flex p-3" ]
                    [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Small viewConfig.currentUser ]
                    , div [ class "flex-grow" ]
                        [ textarea
                            [ id (PostEditor.getTextareaId editor)
                            , class "p-1 w-full h-10 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                            , placeholder "Write a reply..."
                            , onInput NewReplyBodyChanged
                            , onKeydown preventDefault
                                [ ( [ Meta ], enter, \event -> NewReplySubmit )
                                , ( [ Shift, Meta ], enter, \event -> NewReplyAndCloseSubmit )
                                , ( [], esc, \event -> NewReplyEscaped )
                                ]
                            , onBlur NewReplyBlurred
                            , value (PostEditor.getBody editor)
                            , readonly (PostEditor.isSubmitting editor)
                            ]
                            []
                        , PostEditor.filesView editor
                        , div [ class "flex items-baseline justify-end" ]
                            [ viewIf (PostEditor.isUnsubmittable editor) <|
                                button
                                    [ class "mr-2 btn btn-grey-outline btn-sm"
                                    , onClick ClosePostClicked
                                    ]
                                    [ text "Resolve" ]
                            , viewUnless (PostEditor.isUnsubmittable editor) <|
                                button
                                    [ class "mr-2 btn btn-grey-outline btn-sm"
                                    , onClick NewReplyAndCloseSubmit
                                    ]
                                    [ text "Send & Resolve" ]
                            , button
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


replyPromptView : ViewConfig -> Model -> Data -> Html Msg
replyPromptView config model data =
    if not (Connection.isEmpty model.replyIds) then
        button [ class "flex my-4 items-center", onClick ExpandReplyComposer ]
            [ div [ class "flex-no-shrink mr-3" ] [ SpaceUser.avatar Avatar.Small config.currentUser ]
            , div [ class "flex-grow leading-semi-loose text-dusty-blue" ]
                [ text "Reply or resolve..."
                ]
            ]

    else
        text ""


replyButtonView : ViewConfig -> Model -> Data -> Html Msg
replyButtonView config model data =
    if Post.state data.post == Post.Open then
        button
            [ class "tooltip tooltip-bottom"
            , onClick ExpandReplyComposer
            , attribute "data-tooltip" "Reply or Resolve"
            ]
            [ Icons.reply ]

    else
        text ""


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



-- REACTIONS


postReactionButton : Post -> List SpaceUser -> Html Msg
postReactionButton post reactors =
    let
        flyoutLabel =
            if List.isEmpty reactors then
                "Acknowledge"

            else
                "Acknowledged by"
    in
    if Post.hasReacted post then
        button
            [ class "flex relative items-center mr-6 no-outline react-button"
            , onClick DeletePostReactionClicked
            ]
            [ Icons.thumbs Icons.On
            , viewIf (Post.reactionCount post > 0) <|
                div
                    [ class "ml-1 text-green font-bold text-sm"
                    ]
                    [ text <| String.fromInt (Post.reactionCount post) ]
            , div [ classList [ ( "reactors", True ), ( "no-reactors", List.isEmpty reactors ) ] ]
                [ div [ class "text-xs font-bold text-white" ] [ text flyoutLabel ]
                , viewUnless (List.isEmpty reactors) <|
                    div [ class "mt-1" ] (List.map reactorView reactors)
                ]
            ]

    else
        button
            [ class "flex relative items-center mr-6 no-outline react-button"
            , onClick CreatePostReactionClicked
            ]
            [ Icons.thumbs Icons.Off
            , viewIf (Post.reactionCount post > 0) <|
                div
                    [ class "ml-1 text-dusty-blue font-bold text-sm"
                    ]
                    [ text <| String.fromInt (Post.reactionCount post) ]
            , div [ classList [ ( "reactors", True ), ( "no-reactors", List.isEmpty reactors ) ] ]
                [ div [ class "text-xs font-bold text-white" ] [ text flyoutLabel ]
                , viewUnless (List.isEmpty reactors) <|
                    div [ class "mt-1" ] (List.map reactorView reactors)
                ]
            ]


replyReactionButton : Reply -> List SpaceUser -> Html Msg
replyReactionButton reply reactors =
    let
        flyoutLabel =
            if List.isEmpty reactors then
                "Acknowledge"

            else
                "Acknowledged by"
    in
    if Reply.hasReacted reply then
        button
            [ class "flex relative items-center mr-6 no-outline react-button"
            , onClick <| DeleteReplyReactionClicked (Reply.id reply)
            ]
            [ Icons.thumbs Icons.On
            , viewIf (Reply.reactionCount reply > 0) <|
                div
                    [ class "ml-1 text-green font-bold text-sm"
                    ]
                    [ text <| String.fromInt (Reply.reactionCount reply) ]
            , div [ classList [ ( "reactors", True ), ( "no-reactors", List.isEmpty reactors ) ] ]
                [ div [ class "text-xs font-bold text-white" ] [ text flyoutLabel ]
                , viewUnless (List.isEmpty reactors) <|
                    div [ class "mt-1" ] (List.map reactorView reactors)
                ]
            ]

    else
        button
            [ class "flex relative items-center mr-6 no-outline react-button"
            , onClick <| CreateReplyReactionClicked (Reply.id reply)
            ]
            [ Icons.thumbs Icons.Off
            , viewIf (Reply.reactionCount reply > 0) <|
                div
                    [ class "ml-1 text-dusty-blue font-bold text-sm"
                    ]
                    [ text <| String.fromInt (Reply.reactionCount reply) ]
            , div [ classList [ ( "reactors", True ), ( "no-reactors", List.isEmpty reactors ) ] ]
                [ div [ class "text-xs font-bold text-white" ] [ text flyoutLabel ]
                , viewUnless (List.isEmpty reactors) <|
                    div [ class "mt-1" ] (List.map reactorView reactors)
                ]
            ]


reactorView : SpaceUser -> Html Msg
reactorView user =
    div
        [ class "flex items-center pr-4 mb-px no-underline text-white"
        ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Tiny user ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| SpaceUser.displayName user ]
        ]



-- UTILS


postNodeId : String -> String
postNodeId postId =
    "post-" ++ postId


replyNodeId : String -> String
replyNodeId replyId =
    "reply-" ++ replyId


replyComposerId : String -> String
replyComposerId postId =
    "reply-composer-" ++ postId


visibleReplies : Repo -> Connection Id -> ( List Reply, Bool )
visibleReplies repo replyIds =
    let
        replies =
            repo
                |> Repo.getReplies (Connection.toList replyIds)
                |> List.filter Reply.notDeleted

        hasPreviousPage =
            Connection.hasPreviousPage replyIds
    in
    ( replies, hasPreviousPage )


getReplyEditor : Id -> ReplyEditors -> PostEditor
getReplyEditor replyId editors =
    Dict.get replyId editors
        |> Maybe.withDefault (PostEditor.init replyId)
