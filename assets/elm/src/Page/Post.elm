module Page.Post exposing (Model, Msg(..), handleReplyCreated, init, setup, subscriptions, teardown, title, update, view)

import Component.Post
import Connection
import Data.Reply as Reply exposing (Reply)
import Data.Space as Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Html exposing (..)
import Html.Attributes exposing (..)
import Mutation.RecordPostView as RecordPostView
import Query.PostInit as PostInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import View.Helpers exposing (displayName)



-- MODEL


type alias Model =
    { post : Component.Post.Model
    , space : Space
    , user : SpaceUser
    , now : ( Zone, Posix )
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


buildModel : SpaceUser -> Space -> ( ( Session, PostInit.Response ), ( Zone, Posix ) ) -> Task Session.Error ( Session, Model )
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
    | Tick Posix
    | SetCurrentTime Posix Zone
    | NoOp


update : Msg -> Repo -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg repo session ({ post } as model) =
    case msg of
        PostComponentMsg componentMsg ->
            let
                ( ( newPost, cmd ), newSession ) =
                    Component.Post.update componentMsg (Space.getId model.space) session post
            in
            ( ( { model | post = newPost }
              , Cmd.map PostComponentMsg cmd
              )
            , newSession
            )

        ViewRecorded (Ok ( newSession, _ )) ->
            noCmd newSession model

        ViewRecorded (Err Session.Expired) ->
            redirectToLogin session model

        ViewRecorded (Err _) ->
            noCmd session model

        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), session )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
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
    every 1000 Tick



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ postView repo model.space model.user model.now model.post
            , sidebarView repo model.post
            ]
        ]


postView : Repo -> Space -> SpaceUser -> ( Zone, Posix ) -> Component.Post.Model -> Html Msg
postView repo space currentUser now component =
    div [ class "pt-6" ]
        [ Component.Post.postView repo space currentUser now component
            |> Html.map PostComponentMsg
        ]


sidebarView : Repo -> Component.Post.Model -> Html Msg
sidebarView repo component =
    Component.Post.sidebarView repo component
        |> Html.map PostComponentMsg
