module Page.Post exposing (..)

import Date exposing (Date)
import Html exposing (..)
import Task exposing (Task)
import Data.Post exposing (Post)
import Data.Space exposing (Space)
import Data.SpaceUser exposing (SpaceUser)
import Session exposing (Session)
import Query.PostInit as PostInit


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
    = NoOp


update : Model -> ( Model, Cmd Msg )
update model =
    ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    text ""
