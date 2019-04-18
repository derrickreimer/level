module ReplyView exposing (Msg(..), ReplyView, init, update, view)

import Actor
import Avatar
import Browser.Navigation as Nav
import Color
import Dict exposing (Dict)
import File exposing (File)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Mutation.CreateReplyReaction as CreateReplyReaction
import Mutation.DeleteReply as DeleteReply
import Mutation.DeleteReplyReaction as DeleteReplyReaction
import Mutation.UpdateReply as UpdateReply
import PostEditor exposing (PostEditor)
import RenderedHtml
import Reply exposing (Reply)
import ReplyReaction exposing (ReplyReaction)
import Repo exposing (Repo)
import ResolvedAuthor exposing (ResolvedAuthor)
import ResolvedReply exposing (ResolvedReply)
import ResolvedReplyReaction exposing (ResolvedReplyReaction)
import Route
import Route.SpaceUser
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task
import Time exposing (Posix)
import TimeWithZone exposing (TimeWithZone)
import ValidationError
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (onPassiveClick, setFocus, smartFormatTime, unsetFocus, viewIf, viewUnless)



-- MODEL


type alias ReplyView =
    { id : Id
    , spaceId : Id
    , postId : Id
    , postedAt : Posix
    , editor : PostEditor
    , isReactionMenuOpen : Bool
    , customReaction : String
    }


type alias Data =
    { resolvedReply : ResolvedReply
    }


resolveData : Repo -> ReplyView -> Maybe Data
resolveData repo replyView =
    Maybe.map Data
        (ResolvedReply.resolve repo replyView.id)



-- LIFECYCLE


init : Id -> Reply -> ReplyView
init spaceId reply =
    ReplyView
        (Reply.id reply)
        spaceId
        (Reply.postId reply)
        (Reply.postedAt reply)
        (PostEditor.init (Reply.id reply))
        False
        ""



-- UPDATE


type Msg
    = NoOp
    | ExpandEditor
    | CollapseEditor
    | EditorBodyChanged String
    | EditorFileAdded File
    | EditorFileUploadProgress Id Int
    | EditorFileUploaded Id Id String
    | EditorFileUploadError Id
    | EditorSubmitted
    | ReplyUpdated (Result Session.Error ( Session, UpdateReply.Response ))
    | DeleteClicked
    | ReplyDeleted (Result Session.Error ( Session, DeleteReply.Response ))
    | ReactionMenuToggled
    | CustomReactionChanged String
    | CreateReactionClicked String
    | DeleteReactionClicked String
    | ReactionCreated (Result Session.Error ( Session, CreateReplyReaction.Response ))
    | ReactionDeleted (Result Session.Error ( Session, DeleteReplyReaction.Response ))
    | InternalLinkClicked String


update : Msg -> Globals -> ReplyView -> ( ( ReplyView, Cmd Msg ), Globals )
update msg globals replyView =
    case msg of
        NoOp ->
            ( ( replyView, Cmd.none ), globals )

        ExpandEditor ->
            case Repo.getReply replyView.id globals.repo of
                Just reply ->
                    let
                        newEditor =
                            replyView.editor
                                |> PostEditor.expand
                                |> PostEditor.setBody (Reply.body reply)
                                |> PostEditor.setFiles (Reply.files reply)
                                |> PostEditor.clearErrors

                        cmd =
                            setFocus (PostEditor.getTextareaId replyView.editor) NoOp
                    in
                    ( ( { replyView | editor = newEditor }, cmd ), globals )

                Nothing ->
                    ( ( replyView, Cmd.none ), globals )

        CollapseEditor ->
            ( ( { replyView | editor = PostEditor.collapse replyView.editor }, Cmd.none ), globals )

        EditorBodyChanged val ->
            ( ( { replyView | editor = PostEditor.setBody val replyView.editor }, Cmd.none ), globals )

        EditorFileAdded file ->
            ( ( { replyView | editor = PostEditor.addFile file replyView.editor }, Cmd.none ), globals )

        EditorFileUploadProgress clientId percentage ->
            ( ( { replyView | editor = PostEditor.setFileUploadPercentage clientId percentage replyView.editor }, Cmd.none ), globals )

        EditorFileUploaded clientId fileId url ->
            let
                newEditor =
                    replyView.editor
                        |> PostEditor.setFileState clientId (File.Uploaded fileId url)

                cmd =
                    newEditor
                        |> PostEditor.insertFileLink fileId
            in
            ( ( { replyView | editor = newEditor }, cmd ), globals )

        EditorFileUploadError clientId ->
            let
                newEditor =
                    replyView.editor
                        |> PostEditor.setFileState clientId File.UploadError
            in
            ( ( { replyView | editor = newEditor }, Cmd.none ), globals )

        EditorSubmitted ->
            let
                cmd =
                    globals.session
                        |> UpdateReply.request replyView.spaceId replyView.id (PostEditor.getBody replyView.editor)
                        |> Task.attempt ReplyUpdated

                newEditor =
                    replyView.editor
                        |> PostEditor.setToSubmitting
                        |> PostEditor.clearErrors
            in
            ( ( { replyView | editor = newEditor }, cmd ), globals )

        ReplyUpdated (Ok ( newSession, UpdateReply.Success reply )) ->
            let
                newGlobals =
                    { globals | session = newSession, repo = Repo.setReply reply globals.repo }

                newEditor =
                    replyView.editor
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.collapse
            in
            ( ( { replyView | editor = newEditor }, Cmd.none ), newGlobals )

        ReplyUpdated (Ok ( newSession, UpdateReply.Invalid errors )) ->
            let
                newEditor =
                    replyView.editor
                        |> PostEditor.setNotSubmitting
                        |> PostEditor.setErrors errors
            in
            ( ( { replyView | editor = newEditor }, Cmd.none ), globals )

        ReplyUpdated (Err Session.Expired) ->
            redirectToLogin globals replyView

        ReplyUpdated (Err _) ->
            let
                newEditor =
                    replyView.editor
                        |> PostEditor.setNotSubmitting
            in
            ( ( { replyView | editor = newEditor }, Cmd.none ), globals )

        DeleteClicked ->
            let
                newEditor =
                    replyView.editor
                        |> PostEditor.setToSubmitting

                cmd =
                    globals.session
                        |> DeleteReply.request (DeleteReply.variables replyView.spaceId replyView.id)
                        |> Task.attempt ReplyDeleted
            in
            ( ( { replyView | editor = newEditor }, cmd ), globals )

        ReplyDeleted (Ok ( newSession, DeleteReply.Success reply )) ->
            ( ( replyView, Cmd.none ), { globals | session = newSession } )

        ReplyDeleted (Ok ( newSession, DeleteReply.Invalid _ )) ->
            let
                newEditor =
                    replyView.editor
                        |> PostEditor.setNotSubmitting
            in
            ( ( { replyView | editor = newEditor }, Cmd.none )
            , { globals | session = newSession }
            )

        ReplyDeleted (Err Session.Expired) ->
            redirectToLogin globals replyView

        ReplyDeleted (Err _) ->
            let
                newEditor =
                    replyView.editor
                        |> PostEditor.setNotSubmitting
            in
            ( ( { replyView | editor = newEditor }, Cmd.none )
            , globals
            )

        ReactionMenuToggled ->
            ( ( { replyView | isReactionMenuOpen = not replyView.isReactionMenuOpen }, Cmd.none ), globals )

        CustomReactionChanged newValue ->
            if String.length newValue <= 16 then
                ( ( { replyView | customReaction = newValue }, Cmd.none ), globals )

            else
                ( ( replyView, Cmd.none ), globals )

        CreateReactionClicked value ->
            let
                variables =
                    CreateReplyReaction.variables replyView.spaceId replyView.postId replyView.id value

                cmd =
                    globals.session
                        |> CreateReplyReaction.request variables
                        |> Task.attempt ReactionCreated
            in
            ( ( replyView, cmd ), globals )

        ReactionCreated (Ok ( newSession, CreateReplyReaction.Success reply )) ->
            let
                newGlobals =
                    { globals | repo = Repo.setReply reply globals.repo, session = newSession }
            in
            ( ( { replyView | isReactionMenuOpen = False, customReaction = "" }, Cmd.none ), newGlobals )

        ReactionCreated (Err Session.Expired) ->
            redirectToLogin globals replyView

        ReactionCreated _ ->
            ( ( replyView, Cmd.none ), globals )

        DeleteReactionClicked value ->
            let
                variables =
                    DeleteReplyReaction.variables replyView.spaceId replyView.postId replyView.id value

                cmd =
                    globals.session
                        |> DeleteReplyReaction.request variables
                        |> Task.attempt ReactionDeleted
            in
            ( ( replyView, cmd ), globals )

        ReactionDeleted (Ok ( newSession, DeleteReplyReaction.Success reply )) ->
            let
                newGlobals =
                    { globals | repo = Repo.setReply reply globals.repo, session = newSession }
            in
            ( ( replyView, Cmd.none ), newGlobals )

        ReactionDeleted (Err Session.Expired) ->
            redirectToLogin globals replyView

        ReactionDeleted _ ->
            ( ( replyView, Cmd.none ), globals )

        InternalLinkClicked pathname ->
            ( ( replyView, Nav.pushUrl globals.navKey pathname ), globals )


redirectToLogin : Globals -> ReplyView -> ( ( ReplyView, Cmd Msg ), Globals )
redirectToLogin globals replyView =
    ( ( replyView, Route.toLogin ), globals )



-- VIEW


type alias ViewConfig =
    { globals : Globals
    , space : Space
    , currentUser : SpaceUser
    , now : TimeWithZone
    , spaceUsers : List SpaceUser
    , groups : List Group
    , showRecipients : Bool
    }


view : ViewConfig -> ReplyView -> Html Msg
view config replyView =
    case resolveData config.globals.repo replyView of
        Just data ->
            resolvedView config replyView data

        Nothing ->
            text "Something went wrong."


resolvedView : ViewConfig -> ReplyView -> Data -> Html Msg
resolvedView config replyView data =
    let
        reply =
            data.resolvedReply.reply

        author =
            data.resolvedReply.author

        groupedReactions =
            config.globals.repo
                |> Repo.getReplyReactions (Reply.id data.resolvedReply.reply)
                |> List.filterMap (ResolvedReplyReaction.resolve config.globals.repo)
                |> groupReactionsByValue

        trayItems =
            groupedReactionViews config groupedReactions
                ++ [ reactionMenuView config replyView data ]
    in
    div
        [ id (nodeId replyView.id)
        , classList [ ( "flex mt-2 text-md relative", True ) ]
        ]
        [ viewUnless (Reply.hasViewed reply) <|
            div [ class "mr-2 -ml-3 mt-1 w-1 h-9 rounded pin-t bg-orange flex-no-shrink" ] []
        , div [ class "flex-no-shrink mr-3 z-10 pt-1" ] [ Avatar.fromConfig (ResolvedAuthor.avatarConfig Avatar.Small author) ]
        , div
            [ classList
                [ ( "min-w-0 leading-normal -ml-6 px-6 py-2 bg-grey-light rounded-xl", True )
                , ( "flex-grow", PostEditor.isExpanded replyView.editor )
                ]
            ]
            [ div [ class "pb-1/2" ]
                [ authorLabel config.space author
                , View.Helpers.timeTag config.now (TimeWithZone.setPosix (Reply.postedAt reply) config.now) [ class "mr-3 text-sm text-dusty-blue whitespace-no-wrap" ]
                , viewIf (not (PostEditor.isExpanded replyView.editor) && Reply.canEdit reply) <|
                    button
                        [ class "mr-3 text-sm text-dusty-blue"
                        , onClick ExpandEditor
                        ]
                        [ text "Edit" ]
                ]
            , viewUnless (PostEditor.isExpanded replyView.editor) <|
                div []
                    [ div
                        [ classList
                            [ ( "markdown pb-1 break-words fs-block", True )
                            ]
                        ]
                        [ RenderedHtml.node
                            { html = Reply.bodyHtml reply
                            , onInternalLinkClicked = InternalLinkClicked
                            }
                        ]
                    , staticFilesView (Reply.files reply)
                    ]
            , viewIf (PostEditor.isExpanded replyView.editor) <| editorView config replyView.editor
            , viewUnless (PostEditor.isExpanded replyView.editor) <|
                div [ class "flex flex-wrap items-center" ] trayItems
            ]
        ]


authorLabel : Space -> ResolvedAuthor -> Html Msg
authorLabel space author =
    case ResolvedAuthor.actor author of
        Actor.User user ->
            a
                [ Route.href <| Route.SpaceUser (Route.SpaceUser.init (Space.slug space) (SpaceUser.handle user))
                , class "whitespace-no-wrap no-underline"
                ]
                [ span [ class "font-bold text-dusty-blue-darkest mr-2" ] [ text <| ResolvedAuthor.displayName author ]
                , span [ class "ml-2 text-dusty-blue hidden" ] [ text <| "@" ++ ResolvedAuthor.handle author ]
                ]

        _ ->
            span [ class "whitespace-no-wrap" ]
                [ span [ class "font-bold text-dusty-blue-darkest mr-2" ] [ text <| ResolvedAuthor.displayName author ]
                , span [ class "ml-2 text-dusty-blue hidden" ] [ text <| "@" ++ ResolvedAuthor.handle author ]
                ]


editorView : ViewConfig -> PostEditor -> Html Msg
editorView viewConfig editor =
    let
        config =
            { editor = editor
            , spaceId = Space.id viewConfig.space
            , spaceUsers = viewConfig.spaceUsers
            , groups = viewConfig.groups
            , onFileAdded = EditorFileAdded
            , onFileUploadProgress = EditorFileUploadProgress
            , onFileUploaded = EditorFileUploaded
            , onFileUploadError = EditorFileUploadError
            , classList = [ ( "tribute-pin-t", True ) ]
            }
    in
    PostEditor.wrapper config
        [ label [ class "composer my-2 p-0" ]
            [ textarea
                [ id (PostEditor.getTextareaId editor)
                , class "w-full no-outline text-dusty-blue-darkest bg-transparent resize-none leading-normal fs-block"
                , placeholder "Edit reply..."
                , onInput EditorBodyChanged
                , readonly (PostEditor.isSubmitting editor)
                , value (PostEditor.getBody editor)
                , onKeydown preventDefault
                    [ ( [ Meta ], enter, \event -> EditorSubmitted )
                    ]
                ]
                []
            , ValidationError.prefixedErrorView "body" "Body" (PostEditor.getErrors editor)
            , PostEditor.filesView editor
            , div [ class "flex" ]
                [ button
                    [ class "mr-2 btn btn-grey-outline btn-sm"
                    , onClick DeleteClicked
                    ]
                    [ text "Delete reply" ]
                , div [ class "flex-grow flex justify-end" ]
                    [ button
                        [ class "mr-2 btn btn-grey-outline btn-sm"
                        , onClick CollapseEditor
                        ]
                        [ text "Cancel" ]
                    , button
                        [ class "btn btn-blue btn-sm"
                        , onClick EditorSubmitted
                        , disabled (PostEditor.isUnsubmittable editor)
                        ]
                        [ text "Update reply" ]
                    ]
                ]
            ]
        ]


staticFilesView : List File -> Html msg
staticFilesView files =
    viewUnless (List.isEmpty files) <|
        div [ class "pb-2" ] <|
            List.map staticFileView files


staticFileView : File -> Html msg
staticFileView file =
    case File.getState file of
        File.Uploaded id url ->
            a
                [ href url
                , target "_blank"
                , class "flex flex-none items-center mr-4 pb-1 no-underline text-dusty-blue-dark hover:text-blue"
                , rel "tooltip"
                , title "Download file"
                ]
                [ div [ class "mr-2" ] [ File.icon Color.DustyBlue file ]
                , div [ class "text-md truncate" ] [ text <| File.getName file ]
                ]

        _ ->
            text ""


reactionMenuView : ViewConfig -> ReplyView -> Data -> Html Msg
reactionMenuView config replyView data =
    if replyView.isReactionMenuOpen then
        div [ class "flex items-center p-1/2 bg-white rounded-full no-outline" ]
            [ reactButton "👍"
            , reactButton "😊"
            , reactButton "😂"
            , reactButton "🎉"
            , reactButton "😕"
            , input
                [ type_ "text"
                , class "mx-1/2 px-2 h-7 w-20 rounded-full bg-white text-dusty-blue-dark focus:shadow-outline no-outline"
                , placeholder "Custom"
                , onInput CustomReactionChanged
                , value replyView.customReaction
                , onKeydown preventDefault
                    [ ( [], enter, \event -> CreateReactionClicked replyView.customReaction )
                    , ( [ Meta ], enter, \event -> CreateReactionClicked replyView.customReaction )
                    ]
                ]
                []
            , button
                [ class "flex mx-1/2 items-center justify-center w-7 h-7 bg-transparent hover:bg-grey-light transition-bg rounded-full"
                , onClick ReactionMenuToggled
                ]
                [ Icons.exSmall ]
            ]

    else
        button
            [ class "flex items-center justify-center mr-4 w-6 h-6 rounded-full bg-transparent hover:bg-grey-light transition-bg"
            , style "margin-left" "-2px"
            , onClick ReactionMenuToggled
            ]
            [ Icons.reaction ]


reactButton : String -> Html Msg
reactButton value =
    button
        [ class "flex-no-shrink mx-1/2 emoji-reaction hover:text-xl"
        , onClick (CreateReactionClicked value)
        ]
        [ text value ]


groupedReactionViews : ViewConfig -> Dict String (List SpaceUser) -> List (Html Msg)
groupedReactionViews config groupedReactions =
    groupedReactions
        |> Dict.map (groupedReactionView config)
        |> Dict.values


groupedReactionView : ViewConfig -> String -> List SpaceUser -> Html Msg
groupedReactionView config value spaceUsers =
    let
        clickMsg =
            if List.member config.currentUser spaceUsers then
                DeleteReactionClicked value

            else
                CreateReactionClicked value
    in
    button [ class "flex items-center mr-2 py-1/2 bg-white rounded-full no-outline", onClick clickMsg ]
        [ div [ class "flex-no-shrink mx-1/2 emoji-reaction" ] [ text value ]
        , div [ class "flex items-center pl-2 pr-1/2" ] (List.map reactorAvatar spaceUsers)
        ]


reactorAvatar : SpaceUser -> Html Msg
reactorAvatar spaceUser =
    div
        [ class "flex-no-shrink mx-1/2 rounded-full shadow-white -ml-2"
        ]
        [ SpaceUser.avatar Avatar.Tiny spaceUser ]



-- HELPERS


groupReactionsByValue : List ResolvedReplyReaction -> Dict String (List SpaceUser)
groupReactionsByValue resolvedReactions =
    let
        reducer resolvedReaction dict =
            let
                value =
                    ReplyReaction.value resolvedReaction.reaction
            in
            case Dict.get value dict of
                Just users ->
                    Dict.insert value (resolvedReaction.spaceUser :: users) dict

                Nothing ->
                    Dict.insert value [ resolvedReaction.spaceUser ] dict
    in
    List.foldr reducer Dict.empty resolvedReactions



-- MISC


nodeId : Id -> String
nodeId id =
    "reply-" ++ id
