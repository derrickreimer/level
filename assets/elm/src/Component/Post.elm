module Component.Post exposing (Model, Msg(..), update, view)

import Date exposing (Date)
import Dict
import Dom exposing (focus, blur)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Autosize
import Avatar exposing (personAvatar)
import Connection exposing (Connection)
import Data.Reply exposing (Reply)
import Data.ReplyComposers exposing (ReplyComposers, ReplyComposer)
import Data.Post exposing (Post)
import Data.SpaceUser exposing (SpaceUser)
import Icons
import Keys exposing (Modifier(..), preventDefault, onKeydown, enter, esc)
import Mutation.ReplyToPost as ReplyToPost
import Ports
import Route
import Session exposing (Session)
import Util exposing (displayName, smartFormatDate, injectHtml, viewIf, viewUnless)


-- MODEL


type alias Model =
    Post


type alias Id =
    String



-- UPDATE


type Msg
    = ExpandReplyComposer
    | NewReplyBodyChanged String
    | NewReplyBlurred
    | NewReplySubmit
    | NewReplyEscaped
    | NewReplySubmitted (Result Session.Error ( Session, ReplyToPost.Response ))
    | NoOp


update : Msg -> String -> ReplyComposers -> Session -> Model -> ( ( Model, Cmd Msg ), ReplyComposers, Session )
update msg spaceId replyComposers session post =
    case msg of
        ExpandReplyComposer ->
            let
                nodeId =
                    replyComposerId post.id

                cmd =
                    Cmd.batch
                        [ setFocus nodeId
                        , autosize Autosize.Init nodeId
                        ]

                newReplyComposers =
                    case Dict.get post.id replyComposers of
                        Just composer ->
                            Dict.insert post.id { composer | isExpanded = True } replyComposers

                        Nothing ->
                            Dict.insert post.id (ReplyComposer "" True False) replyComposers
            in
                ( ( post, cmd ), newReplyComposers, session )

        NewReplyBodyChanged val ->
            case Dict.get post.id replyComposers of
                Just composer ->
                    let
                        newReplyComposers =
                            Dict.insert post.id { composer | body = val } replyComposers
                    in
                        noCmd session newReplyComposers post

                Nothing ->
                    noCmd session replyComposers post

        NewReplySubmit ->
            case Dict.get post.id replyComposers of
                Just composer ->
                    let
                        newReplyComposers =
                            Dict.insert post.id { composer | isSubmitting = True } replyComposers

                        cmd =
                            ReplyToPost.Params spaceId post.id composer.body
                                |> ReplyToPost.request
                                |> Session.request session
                                |> Task.attempt NewReplySubmitted
                    in
                        ( ( post, cmd ), newReplyComposers, session )

                Nothing ->
                    noCmd session replyComposers post

        NewReplySubmitted (Ok ( session, reply )) ->
            case Dict.get post.id replyComposers of
                Just composer ->
                    let
                        nodeId =
                            replyComposerId post.id

                        newReplyComposers =
                            Dict.insert post.id { composer | body = "", isSubmitting = False } replyComposers
                    in
                        ( ( post, setFocus nodeId ), newReplyComposers, session )

                Nothing ->
                    noCmd session replyComposers post

        NewReplySubmitted (Err Session.Expired) ->
            redirectToLogin session replyComposers post

        NewReplySubmitted (Err _) ->
            noCmd session replyComposers post

        NewReplyEscaped ->
            case Dict.get post.id replyComposers of
                Just composer ->
                    if composer.body == "" then
                        ( ( post, unsetFocus (replyComposerId post.id) ), replyComposers, session )
                    else
                        noCmd session replyComposers post

                Nothing ->
                    noCmd session replyComposers post

        NewReplyBlurred ->
            case Dict.get post.id replyComposers of
                Just composer ->
                    let
                        newReplyComposers =
                            Dict.insert post.id { composer | isExpanded = not (composer.body == "") } replyComposers
                    in
                        noCmd session newReplyComposers post

                Nothing ->
                    noCmd session replyComposers post

        NoOp ->
            noCmd session replyComposers post


noCmd : Session -> ReplyComposers -> Model -> ( ( Model, Cmd Msg ), ReplyComposers, Session )
noCmd session replyComposers model =
    ( ( model, Cmd.none ), replyComposers, session )


redirectToLogin : Session -> ReplyComposers -> Model -> ( ( Model, Cmd Msg ), ReplyComposers, Session )
redirectToLogin session replyComposers model =
    ( ( model, Route.toLogin ), replyComposers, session )



-- VIEW


view : SpaceUser -> Date -> ReplyComposers -> Model -> Html Msg
view currentUser now replyComposers post =
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
            , replyComposerView currentUser replyComposers post
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


replyComposerView : SpaceUser -> ReplyComposers -> Post -> Html Msg
replyComposerView currentUser replyComposers post =
    case Dict.get post.id replyComposers of
        Just composer ->
            if composer.isExpanded then
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
                                , value composer.body
                                , readonly composer.isSubmitting
                                ]
                                []
                            , div [ class "flex justify-end" ]
                                [ button
                                    [ class "btn btn-blue btn-sm"
                                    , onClick NewReplySubmit
                                    , disabled (not (newReplySubmittable composer))
                                    ]
                                    [ text "Post reply" ]
                                ]
                            ]
                        ]
                    ]
            else
                replyPromptView currentUser post

        Nothing ->
            viewUnless (Connection.isEmpty post.replies) <|
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


newReplySubmittable : ReplyComposer -> Bool
newReplySubmittable { body, isSubmitting } =
    not (body == "") && not isSubmitting


replyComposerId : String -> String
replyComposerId postId =
    "reply-composer-" ++ postId


setFocus : String -> Cmd Msg
setFocus id =
    Task.attempt (always NoOp) <| focus id


unsetFocus : String -> Cmd Msg
unsetFocus id =
    Task.attempt (always NoOp) <| blur id


autosize : Autosize.Method -> String -> Cmd Msg
autosize method id =
    Ports.autosize (Autosize.buildArgs method id)
