module Component.Post exposing (Model, Msg(..), update, view)

import Date exposing (Date)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Autosize
import Avatar exposing (personAvatar)
import Connection exposing (Connection)
import Data.Reply exposing (Reply)
import Data.ReplyComposer exposing (ReplyComposer)
import Data.Post exposing (Post)
import Data.SpaceUser exposing (SpaceUser)
import Icons
import Keys exposing (Modifier(..), preventDefault, onKeydown, enter, esc)
import Mutation.ReplyToPost as ReplyToPost
import Route
import Session exposing (Session)
import ViewHelpers exposing (setFocus, unsetFocus, autosize, displayName, smartFormatDate, injectHtml, viewIf, viewUnless)


-- MODEL


type alias Model =
    Post



-- UPDATE


type Msg
    = ExpandReplyComposer
    | NewReplyBodyChanged String
    | NewReplyBlurred
    | NewReplySubmit
    | NewReplyEscaped
    | NewReplySubmitted (Result Session.Error ( Session, ReplyToPost.Response ))
    | NoOp


update : Msg -> String -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg spaceId session post =
    case msg of
        ExpandReplyComposer ->
            let
                nodeId =
                    replyComposerId post.id

                cmd =
                    Cmd.batch
                        [ setFocus nodeId NoOp
                        , autosize Autosize.Init nodeId
                        ]

                newPost =
                    post.replyComposer
                        |> Data.ReplyComposer.expand
                        |> Data.Post.setReplyComposer post
            in
                ( ( newPost, cmd ), session )

        NewReplyBodyChanged val ->
            let
                newPost =
                    post.replyComposer
                        |> Data.ReplyComposer.setBody val
                        |> Data.Post.setReplyComposer post
            in
                noCmd session newPost

        NewReplySubmit ->
            let
                newPost =
                    post.replyComposer
                        |> Data.ReplyComposer.submitting
                        |> Data.Post.setReplyComposer post

                cmd =
                    Data.ReplyComposer.getBody post.replyComposer
                        |> ReplyToPost.Params spaceId post.id
                        |> ReplyToPost.request
                        |> Session.request session
                        |> Task.attempt NewReplySubmitted
            in
                ( ( newPost, cmd ), session )

        NewReplySubmitted (Ok ( session, reply )) ->
            let
                nodeId =
                    replyComposerId post.id

                newPost =
                    post.replyComposer
                        |> Data.ReplyComposer.notSubmitting
                        |> Data.ReplyComposer.setBody ""
                        |> Data.Post.setReplyComposer post
            in
                ( ( newPost, setFocus nodeId NoOp ), session )

        NewReplySubmitted (Err Session.Expired) ->
            redirectToLogin session post

        NewReplySubmitted (Err _) ->
            noCmd session post

        NewReplyEscaped ->
            let
                nodeId =
                    replyComposerId post.id

                replyBody =
                    Data.ReplyComposer.getBody post.replyComposer
            in
                if replyBody == "" then
                    ( ( post, unsetFocus nodeId NoOp ), session )
                else
                    noCmd session post

        NewReplyBlurred ->
            let
                nodeId =
                    replyComposerId post.id

                replyBody =
                    Data.ReplyComposer.getBody post.replyComposer

                composer =
                    if replyBody == "" then
                        post.replyComposer
                            |> Data.ReplyComposer.collapse
                    else
                        post.replyComposer
                            |> Data.ReplyComposer.expand
            in
                noCmd session (Data.Post.setReplyComposer post composer)

        NoOp ->
            noCmd session post


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )


redirectToLogin : Session -> Model -> ( ( Model, Cmd Msg ), Session )
redirectToLogin session model =
    ( ( model, Route.toLogin ), session )



-- VIEW


view : SpaceUser -> Date -> Model -> Html Msg
view currentUser now post =
    div [ class "flex p-4" ]
        [ div [ class "flex-no-shrink mr-4" ] [ personAvatar Avatar.Medium post.author ]
        , div [ class "flex-grow leading-semi-loose" ]
            [ div []
                [ span [ class "font-bold" ] [ text <| displayName post.author ]
                , span [ class "ml-3 text-sm text-dusty-blue" ] [ text <| smartFormatDate now post.postedAt ]
                ]
            , div [ class "markdown mb-2" ] [ injectHtml post.bodyHtml ]
            , div [ class "flex items-center" ]
                [ div [ class "flex-grow" ]
                    [ button [ class "inline-block mr-4", onClick ExpandReplyComposer ] [ Icons.comment ]
                    ]
                ]
            , repliesView post now post.replies
            , replyComposerView currentUser post
            ]
        ]


repliesView : Post -> Date -> Connection Reply -> Html Msg
repliesView post now replies =
    let
        { nodes, hasPreviousPage } =
            Connection.last 5 replies
    in
        viewUnless (Connection.isEmptyAndExpanded replies) <|
            div []
                [ viewIf hasPreviousPage <|
                    a [ Route.href (Route.Post post.id), class "my-2 text-dusty-blue" ] [ text "Show more..." ]
                , div [] (List.map (replyView now) nodes)
                ]


replyView : Date -> Reply -> Html Msg
replyView now reply =
    div [ class "flex my-3" ]
        [ div [ class "flex-no-shrink mr-3" ] [ personAvatar Avatar.Small reply.author ]
        , div [ class "flex-grow leading-semi-loose" ]
            [ div []
                [ span [ class "font-bold" ] [ text <| displayName reply.author ]
                ]
            , div [ class "markdown mb-2" ] [ injectHtml reply.bodyHtml ]
            ]
        ]


replyComposerView : SpaceUser -> Post -> Html Msg
replyComposerView currentUser ({ replyComposer } as post) =
    if Data.ReplyComposer.isExpanded replyComposer then
        div [ class "composer mt-3 -ml-3 p-3" ]
            [ div [ class "flex" ]
                [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Small currentUser ]
                , div [ class "flex-grow" ]
                    [ textarea
                        [ id (replyComposerId post.id)
                        , class "p-1 w-full h-10 no-outline bg-transparent text-dusty-blue-darkest resize-none leading-normal"
                        , placeholder "Write a reply..."
                        , onInput NewReplyBodyChanged
                        , onKeydown preventDefault
                            [ ( [ Meta ], enter, \event -> NewReplySubmit )
                            , ( [], esc, \event -> NewReplyEscaped )
                            ]
                        , onBlur NewReplyBlurred
                        , value (Data.ReplyComposer.getBody replyComposer)
                        , readonly (Data.ReplyComposer.isSubmitting replyComposer)
                        ]
                        []
                    , div [ class "flex justify-end" ]
                        [ button
                            [ class "btn btn-blue btn-sm"
                            , onClick NewReplySubmit
                            , disabled (Data.ReplyComposer.unsubmittable replyComposer)
                            ]
                            [ text "Post reply" ]
                        ]
                    ]
                ]
            ]
    else
        replyPromptView currentUser post


replyPromptView : SpaceUser -> Post -> Html Msg
replyPromptView currentUser post =
    button [ class "flex my-3 items-center", onClick ExpandReplyComposer ]
        [ div [ class "flex-no-shrink mr-3" ] [ personAvatar Avatar.Small currentUser ]
        , div [ class "flex-grow leading-semi-loose text-dusty-blue" ]
            [ text "Write a reply..."
            ]
        ]



-- UTILS


replyComposerId : String -> String
replyComposerId postId =
    "reply-composer-" ++ postId
