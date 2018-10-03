module Component.Post exposing (Mode(..), Model, Msg(..), checkableView, handleReplyCreated, init, setup, teardown, update, view)

import Autosize
import Avatar exposing (personAvatar)
import Connection exposing (Connection)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder, field, maybe, string)
import ListHelpers
import Markdown
import Mutation.CreateReply as CreateReply
import Mutation.DismissPosts as DismissPosts
import Mutation.RecordReplyViews as RecordReplyViews
import Mutation.UpdatePost as UpdatePost
import Post exposing (Post)
import PostEditor exposing (PostEditor)
import Query.Replies
import RenderedHtml
import Reply exposing (Reply)
import ReplyComposer exposing (Mode(..), ReplyComposer)
import Repo exposing (Repo)
import Route
import Route.Group
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Subscription.PostSubscription as PostSubscription
import Task exposing (Task)
import Time exposing (Posix, Zone)
import ValidationError
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (onNonAnchorClick, setFocus, smartFormatTime, unsetFocus, viewIf, viewUnless)



-- MODEL


type alias Model =
    { id : String
    , mode : Mode
    , showGroups : Bool
    , spaceSlug : String
    , postId : Id
    , replyIds : Connection Id
    , replyComposer : ReplyComposer
    , postEditor : PostEditor
    , isChecked : Bool
    }


type Mode
    = Feed
    | FullPage


type alias Data =
    { post : Post
    , author : SpaceUser
    }


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
                (Repo.getSpaceUser (Post.authorId post) repo)

        Nothing ->
            Nothing



-- LIFECYCLE


init : Mode -> Bool -> String -> Id -> Connection Id -> Model
init mode showGroups spaceSlug postId replyIds =
    let
        replyMode =
            case mode of
                Feed ->
                    Autocollapse

                FullPage ->
                    AlwaysExpanded
    in
    Model
        postId
        mode
        showGroups
        spaceSlug
        postId
        replyIds
        (ReplyComposer.init replyMode)
        (PostEditor.init postId)
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


setupReplyComposer : String -> ReplyComposer -> Cmd Msg
setupReplyComposer postId replyComposer =
    if ReplyComposer.isExpanded replyComposer then
        let
            composerId =
                replyComposerId postId
        in
        Cmd.batch
            [ Autosize.init composerId
            , setFocus composerId NoOp
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
    = ExpandReplyComposer
    | NewReplyBodyChanged String
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
    | ClickedInFeed
    | ExpandPostEditor
    | CollapsePostEditor
    | PostEditorBodyChanged String
    | PostEditorSubmitted
    | PostUpdated (Result Session.Error ( Session, UpdatePost.Response ))
    | NoOp


update : Msg -> Id -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg spaceId globals model =
    case msg of
        ExpandReplyComposer ->
            let
                nodeId =
                    replyComposerId model.postId

                cmd =
                    Cmd.batch
                        [ setFocus nodeId NoOp
                        , Autosize.init nodeId
                        , markVisibleRepliesAsViewed globals spaceId model
                        ]

                newModel =
                    { model | replyComposer = ReplyComposer.expand model.replyComposer }
            in
            ( ( newModel, cmd ), globals )

        NewReplyBodyChanged val ->
            let
                newModel =
                    { model | replyComposer = ReplyComposer.setBody val model.replyComposer }
            in
            noCmd globals newModel

        NewReplySubmit ->
            let
                newModel =
                    { model | replyComposer = ReplyComposer.submitting model.replyComposer }

                body =
                    ReplyComposer.getBody model.replyComposer

                cmd =
                    CreateReply.request spaceId model.postId body globals.session
                        |> Task.attempt NewReplySubmitted
            in
            ( ( newModel, cmd ), globals )

        NewReplySubmitted (Ok ( newSession, reply )) ->
            let
                nodeId =
                    replyComposerId model.postId

                newReplyComposer =
                    model.replyComposer
                        |> ReplyComposer.notSubmitting
                        |> ReplyComposer.setBody ""

                newModel =
                    { model | replyComposer = newReplyComposer }
            in
            ( ( newModel, setFocus nodeId NoOp ), { globals | session = newSession } )

        NewReplySubmitted (Err Session.Expired) ->
            redirectToLogin globals model

        NewReplySubmitted (Err _) ->
            noCmd globals model

        NewReplyEscaped ->
            let
                nodeId =
                    replyComposerId model.postId
            in
            ( ( { model | replyComposer = ReplyComposer.escaped model.replyComposer }
              , unsetFocus nodeId NoOp
              )
            , globals
            )

        NewReplyBlurred ->
            let
                nodeId =
                    replyComposerId model.postId

                newModel =
                    { model | replyComposer = ReplyComposer.blurred model.replyComposer }
            in
            noCmd globals newModel

        PreviousRepliesRequested ->
            case Connection.startCursor model.replyIds of
                Just cursor ->
                    let
                        cmd =
                            Query.Replies.request spaceId model.postId cursor 10 globals.session
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
            in
            ( ( model, setFocus nodeId NoOp ), { globals | session = newSession } )

        Dismissed (Err Session.Expired) ->
            redirectToLogin globals model

        Dismissed (Err _) ->
            noCmd globals model

        ClickedInFeed ->
            ( ( model, Route.pushUrl globals.navKey (Route.Post model.spaceSlug model.postId) ), globals )

        ExpandPostEditor ->
            case resolveData globals.repo model of
                Just data ->
                    let
                        nodeId =
                            PostEditor.getId model.postEditor

                        newPostEditor =
                            model.postEditor
                                |> PostEditor.expand
                                |> PostEditor.setBody (Post.body data.post)
                                |> PostEditor.clearErrors

                        cmd =
                            Cmd.batch
                                [ setFocus nodeId NoOp
                                , Autosize.init nodeId
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
            noCmd globals model

        NoOp ->
            noCmd globals model


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



-- VIEWS


view : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> Model -> Html Msg
view repo space currentUser now model =
    case resolveData repo model of
        Just data ->
            resolvedView repo space currentUser now model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> Model -> Data -> Html Msg
resolvedView repo space currentUser (( zone, posix ) as now) model data =
    div [ class "flex" ]
        [ div [ class "flex-no-shrink mr-4" ] [ SpaceUser.avatar Avatar.Medium data.author ]
        , div [ class "flex-grow min-w-0 leading-semi-loose" ]
            [ div []
                [ a
                    [ Route.href <| Route.Post (Space.slug space) model.postId
                    , class "no-underline text-dusty-blue-darkest"
                    , rel "tooltip"
                    , title "Expand post"
                    ]
                    [ span [ class "font-bold" ] [ text <| SpaceUser.displayName data.author ] ]
                , viewIf model.showGroups <|
                    groupsLabel space (Repo.getGroups (Post.groupIds data.post) repo)
                , a
                    [ Route.href <| Route.Post (Space.slug space) model.postId
                    , class "no-underline"
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
                , viewUnless (PostEditor.isExpanded model.postEditor) <|
                    bodyView space model.mode data.post
                , viewIf (PostEditor.isExpanded model.postEditor) <|
                    postEditorView model.postEditor
                , div [ class "flex items-center" ]
                    [ div [ class "flex-grow" ]
                        [ button [ class "inline-block mr-4", onClick ExpandReplyComposer ] [ Icons.comment ]
                        ]
                    ]
                ]
            , div [ class "relative" ]
                [ repliesView repo space data.post now model.replyIds model.mode
                , replyComposerView currentUser data.post model
                ]
            ]
        ]


checkableView : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> Model -> Html Msg
checkableView repo space viewer now model =
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
            [ view repo space viewer now model
            ]
        ]



-- PRIVATE VIEW FUNCTIONS


groupsLabel : Space -> List Group -> Html Msg
groupsLabel space groups =
    case groups of
        [ group ] ->
            span [ class "ml-3 text-sm text-dusty-blue" ]
                [ a
                    [ Route.href (Route.Group (Route.Group.init (Space.slug space) (Group.id group)))
                    , class "no-underline text-dusty-blue font-bold"
                    ]
                    [ text (Group.name group) ]
                ]

        _ ->
            text ""


bodyView : Space -> Mode -> Post -> Html Msg
bodyView space mode post =
    case mode of
        Feed ->
            div
                [ class "markdown mb-2 cursor-pointer select-none"
                , onNonAnchorClick ClickedInFeed
                ]
                [ RenderedHtml.node (Post.bodyHtml post) ]

        FullPage ->
            div [ class "markdown mb-2" ] [ RenderedHtml.node (Post.bodyHtml post) ]


postEditorView : PostEditor -> Html Msg
postEditorView editor =
    label [ class "composer my-2 p-4" ]
        [ textarea
            [ id (PostEditor.getId editor)
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
        , div [ class "flex justify-end" ]
            [ button
                [ class "mr-2 btn btn-grey-outline btn-sm"
                , onClick CollapsePostEditor
                ]
                [ text "Cancel" ]
            , button
                [ class "btn btn-blue btn-sm"
                , onClick PostEditorSubmitted
                , disabled (PostEditor.isSubmitting editor)
                ]
                [ text "Update post" ]
            ]
        ]


repliesView : Repo -> Space -> Post -> ( Zone, Posix ) -> Connection String -> Mode -> Html Msg
repliesView repo space post now replyIds mode =
    let
        ( replies, hasPreviousPage ) =
            visibleReplies repo mode replyIds

        actionButton =
            case mode of
                Feed ->
                    a
                        [ Route.href (Route.Post (Space.slug space) (Post.id post))
                        , class "mb-2 text-dusty-blue no-underline"
                        ]
                        [ text "Show more..." ]

                FullPage ->
                    button
                        [ class "mb-2 text-dusty-blue no-underline"
                        , onClick PreviousRepliesRequested
                        ]
                        [ text "Load more..." ]

        attributes =
            case mode of
                Feed ->
                    [ class "cursor-pointer select-none", onNonAnchorClick ClickedInFeed ]

                FullPage ->
                    []
    in
    viewUnless (Connection.isEmptyAndExpanded replyIds) <|
        div attributes
            [ viewIf hasPreviousPage actionButton
            , div [] (List.map (replyView repo now post) replies)
            ]


replyView : Repo -> ( Zone, Posix ) -> Post -> Reply -> Html Msg
replyView repo (( zone, posix ) as now) post reply =
    case Repo.getSpaceUser (Reply.authorId reply) repo of
        Just author ->
            div
                [ id (replyNodeId (Reply.id reply))
                , classList [ ( "flex mt-3 relative", True ) ]
                ]
                [ viewUnless (Reply.hasViewed reply) <|
                    div [ class "mr-2 -ml-3 w-1 rounded pin-t pin-b bg-turquoise flex-no-shrink" ] []
                , div [ class "flex-no-shrink mr-3" ] [ SpaceUser.avatar Avatar.Small author ]
                , div [ class "flex-grow leading-semi-loose" ]
                    [ div []
                        [ span [ class "font-bold" ] [ text <| SpaceUser.displayName author ]
                        , View.Helpers.time now ( zone, Reply.postedAt reply ) [ class "ml-3 text-sm text-dusty-blue" ]
                        ]
                    , div [ class "markdown mb-2" ]
                        [ RenderedHtml.node (Reply.bodyHtml reply)
                        ]
                    ]
                ]

        Nothing ->
            -- The author was not in the repo as expected, so we can't display the reply
            text ""


replyComposerView : SpaceUser -> Post -> Model -> Html Msg
replyComposerView currentUser post model =
    if ReplyComposer.isExpanded model.replyComposer then
        expandedReplyComposerView currentUser post model

    else
        viewUnless (Connection.isEmpty model.replyIds) <|
            replyPromptView currentUser


expandedReplyComposerView : SpaceUser -> Post -> Model -> Html Msg
expandedReplyComposerView currentUser post model =
    div [ class "-ml-3 py-3 sticky pin-b bg-white" ]
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
            , div [ class "flex p-3" ]
                [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Small currentUser ]
                , div [ class "flex-grow" ]
                    [ textarea
                        [ id (replyComposerId <| Post.id post)
                        , class "p-1 w-full h-10 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                        , placeholder "Write a reply..."
                        , onInput NewReplyBodyChanged
                        , onKeydown preventDefault
                            [ ( [ Meta ], enter, \event -> NewReplySubmit )
                            , ( [], esc, \event -> NewReplyEscaped )
                            ]
                        , onBlur NewReplyBlurred
                        , value (ReplyComposer.getBody model.replyComposer)
                        , readonly (ReplyComposer.isSubmitting model.replyComposer)
                        ]
                        []
                    , div [ class "flex justify-end" ]
                        [ button
                            [ class "btn btn-blue btn-sm"
                            , onClick NewReplySubmit
                            , disabled (ReplyComposer.unsubmittable model.replyComposer)
                            ]
                            [ text "Send" ]
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


statusView : Post.State -> Html Msg
statusView state =
    let
        buildView icon title =
            div [ class "flex items-center text-sm text-dusty-blue-darker" ]
                [ span [ class "mr-2" ] [ icon ]
                , text title
                ]
    in
    case state of
        Post.Open ->
            buildView Icons.open "Open"

        Post.Closed ->
            buildView Icons.closed "Closed"



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
                    Connection.last 3 replyIds
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
