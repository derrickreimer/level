module Page.Post exposing (..)

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (Task)
import Component.Post
import Data.Post exposing (Post)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Query.PostInit as PostInit
import Repo exposing (Repo)
import Session exposing (Session)


-- MODEL


type alias Model =
    { post : Post
    , space : Space
    , user : SpaceUser
    , now : Date
    }


init : SpaceUser -> Space -> String -> Session -> Task Session.Error ( Session, Model )
init user space postId session =
    Date.now
        |> Task.andThen (PostInit.task space.id postId session)
        |> Task.andThen (buildModel user space)


buildModel : SpaceUser -> Space -> ( Session, PostInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space ( session, { post, now } ) =
    Task.succeed ( session, Model post space user now )



-- UPDATE


type Msg
    = PostComponentMsg Component.Post.Msg
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

        NoOp ->
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ postView model.user model.now model.post
            ]
        ]


postView : SpaceUser -> Date -> Post -> Html Msg
postView currentUser now post =
    Component.Post.view currentUser now post
        |> Html.map PostComponentMsg
