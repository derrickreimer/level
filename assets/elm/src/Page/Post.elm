module Page.Post
    exposing
        ( Model
        , Msg(..)
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
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Query.PostInit as PostInit
import Repo exposing (Repo)
import Session exposing (Session)


-- MODEL


type alias Model =
    { post : Component.Post.Model
    , space : Space
    , user : SpaceUser
    , now : Date
    }



-- LIFECYCLE


init : SpaceUser -> Space -> String -> Session -> Task Session.Error ( Session, Model )
init user space postId session =
    Date.now
        |> Task.andThen (PostInit.task space.id postId session)
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
                    Component.Post.update msg model.space.id session post
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


handleReplyCreated : Reply -> Model -> Model
handleReplyCreated reply ({ post } as model) =
    { model | post = Component.Post.handleReplyCreated reply post }



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every second Tick



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ postView model.user model.now model.post
            ]
        ]


postView : SpaceUser -> Date -> Component.Post.Model -> Html Msg
postView currentUser now component =
    Component.Post.view currentUser now component
        |> Html.map PostComponentMsg
