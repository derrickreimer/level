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
import Data.Reply exposing (Reply)
import Data.Space as Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Query.PostInit as PostInit
import Repo exposing (Repo)
import Session exposing (Session)
import ViewHelpers exposing (displayName)


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
    Date.now
        |> Task.andThen (PostInit.request (Space.getId space) postId session)
        |> Task.andThen (buildModel user space)


buildModel : SpaceUser -> Space -> ( Session, PostInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space ( session, { post, now } ) =
    Task.succeed ( session, Model post space user now )


setup : Model -> Cmd Msg
setup { post } =
    Cmd.map PostComponentMsg (Component.Post.setup post)


teardown : Model -> Cmd Msg
teardown { post } =
    Cmd.map PostComponentMsg (Component.Post.teardown post)



-- UPDATE


type Msg
    = PostComponentMsg Component.Post.Msg
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

        Tick time ->
            { model | now = Date.fromTime time }
                |> noCmd session

        NoOp ->
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )



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
    Component.Post.view repo currentUser now component
        |> Html.map PostComponentMsg


sidebarView : Repo -> Component.Post.Model -> Html Msg
sidebarView repo component =
    Component.Post.sidebarView repo component
        |> Html.map PostComponentMsg
