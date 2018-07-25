module Component.Post
    exposing
        ( Model
        , Msg(..)
        , Mode(..)
        , decoder
        , init
        , setup
        , teardown
        , update
        , view
        , handleReplyCreated
        )

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder, field, string)
import Task exposing (Task)
import Autosize
import Avatar exposing (personAvatar)
import Connection exposing (Connection)
import Data.Reply as Reply exposing (Reply)
import Data.Post as Post exposing (Post)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Icons
import Keys exposing (Modifier(..), preventDefault, onKeydown, enter, esc)
import Mutation.ReplyToPost as ReplyToPost
import Query.Replies
import ReplyComposer exposing (ReplyComposer, Mode(..))
import Repo exposing (Repo)
import Route
import Scroll
import Session exposing (Session)
import Subscription.PostSubscription as PostSubscription
import ViewHelpers exposing (setFocus, unsetFocus, displayName, smartFormatDate, injectHtml, viewIf, viewUnless)


-- MODEL


type alias Model =
    { id : String
    , mode : Mode
    , post : Post
    , replyComposer : ReplyComposer
    }


type Mode
    = Feed
    | FullPage



-- LIFECYCLE


decoder : Mode -> Decoder Model
decoder mode =
    Post.decoder
        |> Decode.andThen (Decode.succeed << init mode)


init : Mode -> Post -> Model
init mode post =
    let
        replyMode =
            case mode of
                Feed ->
                    Autocollapse

                FullPage ->
                    AlwaysExpanded
    in
        Model (Post.getId post) mode post (ReplyComposer.init replyMode)


setup : Model -> Cmd Msg
setup { id, mode, replyComposer } =
    Cmd.batch
        [ PostSubscription.subscribe id
        , setupReplyComposer id replyComposer
        , setupScrollPosition mode
        ]


teardown : Model -> Cmd Msg
teardown { id } =
    PostSubscription.unsubscribe id


setupReplyComposer : String -> ReplyComposer -> Cmd Msg
setupReplyComposer postId replyComposer =
    if ReplyComposer.isExpanded replyComposer then
        Autosize.init (replyComposerId postId)
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
    | NewReplySubmitted (Result Session.Error ( Session, ReplyToPost.Response ))
    | PreviousRepliesRequested
    | PreviousRepliesFetched (Result Session.Error ( Session, Query.Replies.Response ))
    | NoOp


update : Msg -> String -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg spaceId session ({ post, replyComposer } as model) =
    case msg of
        ExpandReplyComposer ->
            let
                nodeId =
                    replyComposerId model.id

                cmd =
                    Cmd.batch
                        [ setFocus nodeId NoOp
                        , Autosize.init nodeId
                        ]

                newModel =
                    { model | replyComposer = ReplyComposer.expand replyComposer }
            in
                ( ( newModel, cmd ), session )

        NewReplyBodyChanged val ->
            let
                newModel =
                    { model | replyComposer = ReplyComposer.setBody val replyComposer }
            in
                noCmd session newModel

        NewReplySubmit ->
            let
                newModel =
                    { model | replyComposer = ReplyComposer.submitting replyComposer }

                body =
                    ReplyComposer.getBody replyComposer

                cmd =
                    ReplyToPost.request spaceId (Post.getId post) body session
                        |> Task.attempt NewReplySubmitted
            in
                ( ( newModel, cmd ), session )

        NewReplySubmitted (Ok ( session, reply )) ->
            let
                nodeId =
                    replyComposerId (Post.getId post)

                newReplyComposer =
                    replyComposer
                        |> ReplyComposer.notSubmitting
                        |> ReplyComposer.setBody ""

                newModel =
                    { model | replyComposer = newReplyComposer }
            in
                ( ( newModel, setFocus nodeId NoOp ), session )

        NewReplySubmitted (Err Session.Expired) ->
            redirectToLogin session model

        NewReplySubmitted (Err _) ->
            noCmd session model

        NewReplyEscaped ->
            let
                nodeId =
                    replyComposerId model.id

                replyBody =
                    ReplyComposer.getBody replyComposer
            in
                if replyBody == "" then
                    ( ( model, unsetFocus nodeId NoOp ), session )
                else
                    noCmd session model

        NewReplyBlurred ->
            let
                nodeId =
                    replyComposerId model.id

                replyBody =
                    ReplyComposer.getBody replyComposer

                newModel =
                    { model | replyComposer = ReplyComposer.blurred replyComposer }
            in
                noCmd session newModel

        PreviousRepliesRequested ->
            let
                postData =
                    Post.getCachedData model.post
            in
                case Connection.startCursor postData.replies of
                    Just cursor ->
                        let
                            cmd =
                                Query.Replies.request spaceId (Post.getId model.post) cursor 10 session
                                    |> Task.attempt PreviousRepliesFetched
                        in
                            ( ( model, cmd ), session )

                    Nothing ->
                        noCmd session model

        PreviousRepliesFetched (Ok ( session, response )) ->
            let
                postData =
                    Post.getCachedData model.post

                firstReply =
                    Connection.head postData.replies

                newPost =
                    Post.prependReplies response.replies model.post

                cmd =
                    case firstReply of
                        Just reply ->
                            Scroll.toAnchor Scroll.Document (replyNodeId (Reply.getId reply)) 200

                        Nothing ->
                            Cmd.none
            in
                ( ( { model | post = newPost }, cmd ), session )

        PreviousRepliesFetched (Err Session.Expired) ->
            redirectToLogin session model

        PreviousRepliesFetched (Err _) ->
            noCmd session model

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
handleReplyCreated reply ({ post, mode } as model) =
    let
        cmd =
            case mode of
                FullPage ->
                    Scroll.toBottom Scroll.Document

                _ ->
                    Cmd.none
    in
        if Reply.getPostId reply == Post.getId post then
            ( { model | post = Post.appendReply reply post }, cmd )
        else
            ( model, Cmd.none )



-- VIEW


view : Repo -> SpaceUser -> Date -> Model -> Html Msg
view repo currentUser now ({ post } as model) =
    let
        currentUserData =
            currentUser
                |> Repo.getSpaceUser repo

        postData =
            Post.getCachedData post

        authorData =
            postData.author
                |> Repo.getSpaceUser repo
    in
        div [ classList [ ( "flex pt-4 px-4", True ), ( "pb-4", not (model.mode == FullPage) ) ] ]
            [ div [ class "flex-no-shrink mr-4" ] [ personAvatar Avatar.Medium authorData ]
            , div [ class "flex-grow leading-semi-loose" ]
                [ div []
                    [ div []
                        [ span [ class "font-bold" ] [ text <| displayName authorData ]
                        , span [ class "ml-3 text-sm text-dusty-blue" ] [ text <| smartFormatDate now postData.postedAt ]
                        ]
                    , div [ class "markdown mb-2" ] [ injectHtml postData.bodyHtml ]
                    , viewIf (model.mode == Feed) <|
                        div [ class "flex items-center" ]
                            [ div [ class "flex-grow" ]
                                [ button [ class "inline-block mr-4", onClick ExpandReplyComposer ] [ Icons.comment ]
                                ]
                            ]
                    ]
                , div [ class "relative" ]
                    [ repliesView repo post now postData.replies model.mode
                    , replyComposerView currentUserData model
                    ]
                ]
            ]


repliesView : Repo -> Post -> Date -> Connection Reply -> Mode -> Html Msg
repliesView repo post now replies mode =
    let
        listView =
            case mode of
                Feed ->
                    feedRepliesView repo post now replies

                FullPage ->
                    fullPageRepliesView repo post now replies
    in
        viewUnless (Connection.isEmptyAndExpanded replies) listView


feedRepliesView : Repo -> Post -> Date -> Connection Reply -> Html Msg
feedRepliesView repo post now replies =
    let
        { nodes, hasPreviousPage } =
            Connection.last 5 replies
    in
        div []
            [ viewIf hasPreviousPage <|
                a
                    [ Route.href (Route.Post <| Post.getId post)
                    , class "mb-2 text-dusty-blue no-underline"
                    ]
                    [ text "Show more..." ]
            , div [] (List.map (replyView repo now Feed) nodes)
            ]


fullPageRepliesView : Repo -> Post -> Date -> Connection Reply -> Html Msg
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
            , div [] (List.map (replyView repo now FullPage) nodes)
            ]


replyView : Repo -> Date -> Mode -> Reply -> Html Msg
replyView repo now mode reply =
    let
        replyData =
            Reply.getCachedData reply

        authorData =
            Repo.getSpaceUser repo replyData.author
    in
        div [ id (replyNodeId replyData.id), class "flex mt-3" ]
            [ div [ class "flex-no-shrink mr-3" ] [ personAvatar Avatar.Small authorData ]
            , div [ class "flex-grow leading-semi-loose" ]
                [ div []
                    [ span [ class "font-bold" ] [ text <| displayName authorData ]
                    , viewIf (mode == FullPage) <|
                        span [ class "ml-3 text-sm text-dusty-blue" ] [ text <| smartFormatDate now replyData.postedAt ]
                    ]
                , div [ class "markdown mb-2" ] [ injectHtml replyData.bodyHtml ]
                ]
            ]


replyComposerView : SpaceUser.Record -> Model -> Html Msg
replyComposerView currentUserData { post, replyComposer } =
    if ReplyComposer.isExpanded replyComposer then
        div [ class "-ml-3 py-3 sticky pin-b bg-white" ]
            [ div [ class "composer p-3" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Small currentUserData ]
                    , div [ class "flex-grow" ]
                        [ textarea
                            [ id (replyComposerId <| Post.getId post)
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
                                [ text "Post reply" ]
                            ]
                        ]
                    ]
                ]
            ]
    else
        viewIf (Post.hasReplies post) <|
            replyPromptView currentUserData


replyPromptView : SpaceUser.Record -> Html Msg
replyPromptView currentUserData =
    button [ class "flex my-3 items-center", onClick ExpandReplyComposer ]
        [ div [ class "flex-no-shrink mr-3" ] [ personAvatar Avatar.Small currentUserData ]
        , div [ class "flex-grow leading-semi-loose text-dusty-blue" ]
            [ text "Write a reply..."
            ]
        ]



-- UTILS


replyNodeId : String -> String
replyNodeId replyId =
    "reply-" ++ replyId


replyComposerId : String -> String
replyComposerId postId =
    "reply-composer-" ++ postId
