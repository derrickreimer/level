module Page.Post
    exposing
        ( Model
        , Msg(..)
        , title
        , init
        , setup
        , teardown
        , update
        , subscriptions
        , view
        , handleReplyCreated
        )

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (Task)
import Time exposing (Time, every, second)
import Component.Post
import Connection
import Data.Reply as Reply exposing (Reply)
import Data.Space as Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Mutation.RecordPostView as RecordPostView
import Query.PostInit as PostInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import TaskHelpers
import View.Helpers exposing (displayName)


-- MODEL


type alias Model =
    { post : Component.Post.Model
    , space : Space
    , user : SpaceUser
    , now : Date
    }



-- PAGE PROPERTIES


title : Repo -> Model -> String
title repo { user } =
    let
        userData =
            Repo.getSpaceUser repo user

        name =
            displayName userData
    in
        "View post from " ++ name



-- LIFECYCLE


init : SpaceUser -> Space -> String -> Session -> Task Session.Error ( Session, Model )
init user space postId session =
    session
        |> PostInit.request (Space.getId space) postId
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.andThen (buildModel user space)


buildModel : SpaceUser -> Space -> ( ( Session, PostInit.Response ), Date ) -> Task Session.Error ( Session, Model )
buildModel user space ( ( session, { post } ), now ) =
    Task.succeed ( session, Model post space user now )


setup : Session -> Model -> Cmd Msg
setup session ({ post } as model) =
    Cmd.batch
        [ Cmd.map PostComponentMsg (Component.Post.setup post)
        , recordView session model
        ]


teardown : Model -> Cmd Msg
teardown { post } =
    Cmd.map PostComponentMsg (Component.Post.teardown post)


recordView : Session -> Model -> Cmd Msg
recordView session { space, post } =
    let
        { nodes } =
            Connection.last 1 post.replies

        maybeReplyId =
            case nodes of
                [ lastReply ] ->
                    Just (Reply.getId lastReply)

                _ ->
                    Nothing
    in
        session
            |> RecordPostView.request (Space.getId space) post.id maybeReplyId
            |> Task.attempt ViewRecorded



-- UPDATE


type Msg
    = PostComponentMsg Component.Post.Msg
    | ViewRecorded (Result Session.Error ( Session, RecordPostView.Response ))
    | Tick Time
    | NoOp


update : Msg -> Repo -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg repo session ({ post } as model) =
    case msg of
        PostComponentMsg msg ->
            let
                ( ( newPost, cmd ), newSession ) =
                    Component.Post.update msg (Space.getId model.space) session post
            in
                ( ( { model | post = newPost }
                  , Cmd.map PostComponentMsg cmd
                  )
                , newSession
                )

        ViewRecorded (Ok ( session, _ )) ->
            noCmd session model

        ViewRecorded (Err Session.Expired) ->
            redirectToLogin session model

        ViewRecorded (Err _) ->
            noCmd session model

        Tick time ->
            { model | now = Date.fromTime time }
                |> noCmd session

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
handleReplyCreated reply ({ post } as model) =
    let
        ( newPost, cmd ) =
            Component.Post.handleReplyCreated reply post
    in
        ( { model | post = newPost }, Cmd.map PostComponentMsg cmd )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every second Tick



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ postView repo model.user model.now model.post
            , sidebarView repo model.post
            ]
        ]


postView : Repo -> SpaceUser -> Date -> Component.Post.Model -> Html Msg
postView repo currentUser now component =
    div [ class "pt-6" ]
        [ Component.Post.postView repo currentUser now component
            |> Html.map PostComponentMsg
        ]


sidebarView : Repo -> Component.Post.Model -> Html Msg
sidebarView repo component =
    Component.Post.sidebarView repo component
        |> Html.map PostComponentMsg
