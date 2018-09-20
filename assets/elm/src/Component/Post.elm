module Component.Post exposing (Mode(..), Model, Msg(..), checkableView, decoder, handleMentionsDismissed, handleReplyCreated, init, setup, teardown, update, view)

import Autosize
import Avatar exposing (personAvatar)
import Connection exposing (Connection)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Json.Decode as Decode exposing (Decoder, field, maybe, string)
import ListHelpers
import Markdown
import Mention exposing (Mention)
import Mutation.CreateReply as CreateReply
import NewRepo exposing (NewRepo)
import Post exposing (Post)
import Post.Types
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
import View.Helpers exposing (displayName, setFocus, smartFormatTime, unsetFocus, viewIf, viewUnless)



-- MODEL


type alias Model =
    { id : String
    , mode : Mode
    , showGroups : Bool
    , postId : String
    , replies : Connection Reply
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


resolveData : NewRepo -> Model -> Maybe Data
resolveData repo model =
    let
        maybePost =
            NewRepo.getPost model.postId repo
    in
    case maybePost of
        Just post ->
            Maybe.map2 Data
                (Just post)
                (NewRepo.getSpaceUser (Post.authorId post) repo)

        Nothing ->
            Nothing



-- LIFECYCLE


decoder : Mode -> Bool -> Decoder Model
decoder mode showGroups =
    Decode.map2 (init mode showGroups)
        Post.decoder
        (field "replies" <| Connection.decoder Reply.decoder)


init : Mode -> Bool -> Post -> Connection Reply -> Model
init mode showGroups post replies =
    let
        replyMode =
            case mode of
                Feed ->
                    Autocollapse

                FullPage ->
                    AlwaysExpanded
    in
    Model (Post.id post) mode showGroups (Post.id post) replies (ReplyComposer.init replyMode) False


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


update : Msg -> String -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg spaceId session model =
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
            ( ( newModel, cmd ), session )

        NewReplyBodyChanged val ->
            let
                newModel =
                    { model | replyComposer = ReplyComposer.setBody val model.replyComposer }
            in
            noCmd session newModel

        NewReplySubmit ->
            let
                newModel =
                    { model | replyComposer = ReplyComposer.submitting model.replyComposer }

                body =
                    ReplyComposer.getBody model.replyComposer

                cmd =
                    CreateReply.request spaceId model.postId body session
                        |> Task.attempt NewReplySubmitted
            in
            ( ( newModel, cmd ), session )

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
            ( ( newModel, setFocus nodeId NoOp ), newSession )

        NewReplySubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NewReplySubmitted (Err _) ->
            noCmd session model

        NewReplyEscaped ->
            let
                nodeId =
                    replyComposerId model.postId

                replyBody =
                    ReplyComposer.getBody model.replyComposer
            in
            if replyBody == "" then
                ( ( model, unsetFocus nodeId NoOp ), session )

            else
                noCmd session model

        NewReplyBlurred ->
            let
                nodeId =
                    replyComposerId model.postId

                newModel =
                    { model | replyComposer = ReplyComposer.blurred model.replyComposer }
            in
            noCmd session newModel

        PreviousRepliesRequested ->
            case Connection.startCursor model.replies of
                Just cursor ->
                    let
                        cmd =
                            Query.Replies.request spaceId model.postId cursor 10 session
                                |> Task.attempt PreviousRepliesFetched
                    in
                    ( ( model, cmd ), session )

                Nothing ->
                    noCmd session model

        PreviousRepliesFetched (Ok ( newSession, response )) ->
            let
                firstReply =
                    Connection.head model.replies

                newReplies =
                    Connection.prependConnection response.replies model.replies

                cmd =
                    case firstReply of
                        Just reply ->
                            Scroll.toAnchor Scroll.Document (replyNodeId (Reply.id reply)) 200

                        Nothing ->
                            Cmd.none
            in
            ( ( { model | replies = newReplies }, cmd ), newSession )

        PreviousRepliesFetched (Err Session.Expired) ->
            redirectToLogin session model

        PreviousRepliesFetched (Err _) ->
            noCmd session model

        SelectionToggled ->
            ( ( { model | isChecked = not model.isChecked }, Cmd.none ), session )

        NoOp ->
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )



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
    if Reply.getPostId reply == model.postId then
        ( { model | replies = Connection.append Reply.id reply model.replies }, cmd )

    else
        ( model, Cmd.none )


handleMentionsDismissed : Model -> ( Model, Cmd Msg )
handleMentionsDismissed model =
    ( model, Cmd.none )



-- VIEWS


view : Repo -> NewRepo -> Space -> SpaceUser -> ( Zone, Posix ) -> Model -> Html Msg
view repo newRepo space currentUser now model =
    case resolveData newRepo model of
        Just data ->
            resolvedView repo newRepo space currentUser now model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> NewRepo -> Space -> SpaceUser -> ( Zone, Posix ) -> Model -> Data -> Html Msg
resolvedView repo newRepo space currentUser (( zone, posix ) as now) ({ replies } as model) data =
    div [ class "flex" ]
        [ div [ class "flex-no-shrink mr-4" ] [ SpaceUser.avatar Avatar.Medium data.author ]
        , div [ class "flex-grow leading-semi-loose" ]
            [ div []
                [ a
                    [ Route.href <| Route.Post (Space.getSlug space) model.postId
                    , class "no-underline text-dusty-blue-darkest"
                    , rel "tooltip"
                    , title "Expand post"
                    ]
                    [ span [ class "font-bold" ] [ text <| SpaceUser.displayName data.author ] ]
                , viewIf model.showGroups <|
                    groupsLabel repo space (NewRepo.getGroups (Post.groupIds data.post) newRepo)
                , a
                    [ Route.href <| Route.Post (Space.getSlug space) model.postId
                    , class "no-underline text-dusty-blue-darkest"
                    , rel "tooltip"
                    , title "Expand post"
                    ]
                    [ View.Helpers.time now ( zone, Post.postedAt data.post ) [ class "ml-3 text-sm text-dusty-blue" ] ]
                , div [ class "markdown mb-2" ] [ RenderedHtml.node (Post.bodyHtml repo data.post) ]
                , div [ class "flex items-center" ]
                    [ div [ class "flex-grow" ]
                        [ button [ class "inline-block mr-4", onClick ExpandReplyComposer ] [ Icons.comment ]
                        ]
                    ]
                ]
            , div [ class "relative" ]
                [ repliesView repo space data.post now replies model.mode
                , replyComposerView currentUser data.post model
                ]
            ]
        ]


checkableView : Repo -> NewRepo -> Space -> SpaceUser -> ( Zone, Posix ) -> Model -> Html Msg
checkableView repo newRepo space viewer now model =
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
            [ view repo newRepo space viewer now model
            ]
        ]



-- PRIVATE VIEW FUNCTIONS


groupsLabel : Repo -> Space -> List Group -> Html Msg
groupsLabel repo space groups =
    case groups of
        [ group ] ->
            let
                groupData =
                    Repo.getGroup repo group
            in
            span [ class "ml-3 text-sm text-dusty-blue" ]
                [ a
                    [ Route.href (Route.Group (Route.Group.Root (Space.getSlug space) groupData.id))
                    , class "no-underline text-dusty-blue font-bold"
                    ]
                    [ text groupData.name ]
                ]

        _ ->
            text ""


repliesView : Repo -> Space -> Post -> ( Zone, Posix ) -> Connection Reply -> Mode -> Html Msg
repliesView repo space post now replies mode =
    let
        listView =
            case mode of
                Feed ->
                    feedRepliesView repo space post now replies

                FullPage ->
                    fullPageRepliesView repo post now replies
    in
    viewUnless (Connection.isEmptyAndExpanded replies) listView


feedRepliesView : Repo -> Space -> Post -> ( Zone, Posix ) -> Connection Reply -> Html Msg
feedRepliesView repo space post now replies =
    let
        { nodes, hasPreviousPage } =
            Connection.last 5 replies
    in
    div []
        [ viewIf hasPreviousPage <|
            a
                [ Route.href (Route.Post (Space.getSlug space) (Post.id post))
                , class "mb-2 text-dusty-blue no-underline"
                ]
                [ text "Show more..." ]
        , div [] (List.map (replyView repo now Feed post) nodes)
        ]


fullPageRepliesView : Repo -> Post -> ( Zone, Posix ) -> Connection Reply -> Html Msg
fullPageRepliesView repo post now replies =
    let
        nodes =
            Connection.toList replies

        hasPreviousPage =
            Connection.hasPreviousPage replies
    in
    div []
        [ viewIf hasPreviousPage <|
            button
                [ class "mb-2 text-dusty-blue no-underline"
                , onClick PreviousRepliesRequested
                ]
                [ text "Load more..." ]
        , div [] (List.map (replyView repo now FullPage post) nodes)
        ]


replyView : Repo -> ( Zone, Posix ) -> Mode -> Post -> Reply -> Html Msg
replyView repo (( zone, posix ) as now) mode post reply =
    let
        replyData =
            Reply.getCachedData reply

        authorData =
            Repo.getSpaceUser repo replyData.author
    in
    div
        [ id (replyNodeId replyData.id)
        , classList [ ( "flex mt-3", True ) ]
        ]
        [ div [ class "flex-no-shrink mr-3" ] [ personAvatar Avatar.Small authorData ]
        , div [ class "flex-grow leading-semi-loose" ]
            [ div []
                [ span [ class "font-bold" ] [ text <| displayName authorData ]
                , View.Helpers.time now ( zone, replyData.postedAt ) [ class "ml-3 text-sm text-dusty-blue" ]
                ]
            , div [ class "markdown mb-2" ]
                [ RenderedHtml.node replyData.bodyHtml
                ]
            ]
        ]


replyComposerView : SpaceUser -> Post -> Model -> Html Msg
replyComposerView currentUser post { replies, replyComposer } =
    if ReplyComposer.isExpanded replyComposer then
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
                            , value (ReplyComposer.getBody replyComposer)
                            , readonly (ReplyComposer.isSubmitting replyComposer)
                            ]
                            []
                        , div [ class "flex justify-end" ]
                            [ button
                                [ class "btn btn-blue btn-sm"
                                , onClick NewReplySubmit
                                , disabled (ReplyComposer.unsubmittable replyComposer)
                                ]
                                [ text "Send" ]
                            ]
                        ]
                    ]
                ]
            ]

    else
        viewUnless (Connection.isEmpty replies) <|
            replyPromptView currentUser


replyPromptView : SpaceUser -> Html Msg
replyPromptView currentUser =
    button [ class "flex my-3 items-center", onClick ExpandReplyComposer ]
        [ div [ class "flex-no-shrink mr-3" ] [ SpaceUser.avatar Avatar.Small currentUser ]
        , div [ class "flex-grow leading-semi-loose text-dusty-blue" ]
            [ text "Write a reply..."
            ]
        ]


statusView : Post.Types.State -> Html Msg
statusView state =
    let
        buildView icon title =
            div [ class "flex items-center text-sm text-dusty-blue-darker" ]
                [ span [ class "mr-2" ] [ icon ]
                , text title
                ]
    in
    case state of
        Post.Types.Open ->
            buildView Icons.open "Open"

        Post.Types.Closed ->
            buildView Icons.closed "Closed"



-- UTILS


replyNodeId : String -> String
replyNodeId replyId =
    "reply-" ++ replyId


replyComposerId : String -> String
replyComposerId postId =
    "reply-composer-" ++ postId
