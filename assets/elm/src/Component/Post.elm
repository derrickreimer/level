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
import Json.Decode as Decode exposing (Decoder, field, maybe, string)
import ListHelpers
import Markdown
import Mutation.CreateReply as CreateReply
import Post exposing (Post)
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
import Vendor.Keys as Keys exposing (Modifier(..), enter, esc, onKeydown, preventDefault)
import View.Helpers exposing (setFocus, smartFormatTime, unsetFocus, viewIf, viewUnless)



-- MODEL


type alias Model =
    { id : String
    , mode : Mode
    , showGroups : Bool
    , postId : String
    , replyIds : Connection String
    , replyComposer : ReplyComposer
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


init : Mode -> Bool -> String -> Connection String -> Model
init mode showGroups postId replyIds =
    let
        replyMode =
            case mode of
                Feed ->
                    Autocollapse

                FullPage ->
                    AlwaysExpanded
    in
    Model postId mode showGroups postId replyIds (ReplyComposer.init replyMode) False


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
    | SelectionToggled
    | NoOp


update : Msg -> String -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
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

                replyBody =
                    ReplyComposer.getBody model.replyComposer
            in
            if replyBody == "" then
                ( ( model, unsetFocus nodeId NoOp ), globals )

            else
                noCmd globals model

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

                cmd =
                    case maybeFirstReplyId of
                        Just firstReplyId ->
                            Scroll.toAnchor Scroll.Document (replyNodeId firstReplyId) 200

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | replyIds = newReplyIds }, cmd ), newGlobals )

        PreviousRepliesFetched (Err Session.Expired) ->
            redirectToLogin globals model

        PreviousRepliesFetched (Err _) ->
            noCmd globals model

        SelectionToggled ->
            ( ( { model | isChecked = not model.isChecked }, Cmd.none ), globals )

        NoOp ->
            noCmd globals model


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



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
        , div [ class "flex-grow leading-semi-loose" ]
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
                    , class "no-underline text-dusty-blue-darkest"
                    , rel "tooltip"
                    , title "Expand post"
                    ]
                    [ View.Helpers.time now ( zone, Post.postedAt data.post ) [ class "ml-3 text-sm text-dusty-blue" ] ]
                , div [ class "markdown mb-2" ] [ RenderedHtml.node (Post.bodyHtml data.post) ]
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
        [ div [ class "mr-1 py-2 flex-0" ]
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
                    [ Route.href (Route.Group (Route.Group.Root (Space.slug space) (Group.id group)))
                    , class "no-underline text-dusty-blue font-bold"
                    ]
                    [ text (Group.name group) ]
                ]

        _ ->
            text ""


repliesView : Repo -> Space -> Post -> ( Zone, Posix ) -> Connection String -> Mode -> Html Msg
repliesView repo space post now replyIds mode =
    let
        listView =
            case mode of
                Feed ->
                    feedRepliesView repo space post now replyIds

                FullPage ->
                    fullPageRepliesView repo post now replyIds
    in
    viewUnless (Connection.isEmptyAndExpanded replyIds) listView


feedRepliesView : Repo -> Space -> Post -> ( Zone, Posix ) -> Connection String -> Html Msg
feedRepliesView repo space post now replyIds =
    let
        { nodes, hasPreviousPage } =
            Connection.last 5 replyIds

        replies =
            Repo.getReplies nodes repo
    in
    div []
        [ viewIf hasPreviousPage <|
            a
                [ Route.href (Route.Post (Space.slug space) (Post.id post))
                , class "mb-2 text-dusty-blue no-underline"
                ]
                [ text "Show more..." ]
        , div [] (List.map (replyView repo now Feed post) replies)
        ]


fullPageRepliesView : Repo -> Post -> ( Zone, Posix ) -> Connection String -> Html Msg
fullPageRepliesView repo post now replyIds =
    let
        replies =
            Repo.getReplies (Connection.toList replyIds) repo

        hasPreviousPage =
            Connection.hasPreviousPage replyIds
    in
    div []
        [ viewIf hasPreviousPage <|
            button
                [ class "mb-2 text-dusty-blue no-underline"
                , onClick PreviousRepliesRequested
                ]
                [ text "Load more..." ]
        , div [] (List.map (replyView repo now FullPage post) replies)
        ]


replyView : Repo -> ( Zone, Posix ) -> Mode -> Post -> Reply -> Html Msg
replyView repo (( zone, posix ) as now) mode post reply =
    let
        author =
            Reply.author reply
    in
    div
        [ id (replyNodeId (Reply.id reply))
        , classList [ ( "flex mt-3", True ) ]
        ]
        [ div [ class "flex-no-shrink mr-3" ] [ SpaceUser.avatar Avatar.Small author ]
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


replyComposerView : SpaceUser -> Post -> Model -> Html Msg
replyComposerView currentUser post model =
    if ReplyComposer.isExpanded model.replyComposer then
        div [ class "-ml-3 py-3 sticky pin-b bg-white" ]
            [ div [ class "composer p-3" ]
                [ div [ class "flex" ]
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

    else
        viewUnless (Connection.isEmpty model.replyIds) <|
            replyPromptView currentUser


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
