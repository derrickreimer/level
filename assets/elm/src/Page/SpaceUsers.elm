module Page.SpaceUsers
    exposing
        ( Model
        , Msg(..)
        , title
        , init
        , setup
        , teardown
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (Task)
import Connection exposing (Connection)
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Query.SpaceUsersInit as SpaceUsersInit
import Repo exposing (Repo)
import Route.SpaceUsers exposing (Params)
import Session exposing (Session)


-- MODEL


type alias Model =
    { space : Space
    , user : SpaceUser
    , spaceUsers : Connection SpaceUser
    , params : Params
    }



-- PAGE ATTRIBUTES


title : String
title =
    "Directory"



-- LIFECYCLE


init : SpaceUser -> Space -> Params -> Session -> Task Session.Error ( Session, Model )
init user space params session =
    session
        |> SpaceUsersInit.request (Space.getId space) params 20
        |> Task.andThen (buildModel user space params)


buildModel : SpaceUser -> Space -> Params -> ( Session, SpaceUsersInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space params ( session, { spaceUsers } ) =
    Task.succeed ( session, Model space user spaceUsers params )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp


update : Msg -> Repo -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg repo session model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), session )



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    text ""
