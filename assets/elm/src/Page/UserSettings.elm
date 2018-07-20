module Page.UserSettings
    exposing
        ( Model
        , Msg(..)
        , init
        , setup
        , teardown
        , update
        , view
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Task exposing (Task)
import Query.UserSettingsInit as UserSettingsInit
import Repo exposing (Repo)
import Session exposing (Session)


-- MODEL


type alias Model =
    { firstName : String
    , lastName : String
    , email : String
    }



-- LIFECYCLE


init : Session -> Task Session.Error ( Session, Model )
init session =
    UserSettingsInit.request session
        |> Task.andThen buildModel


buildModel : ( Session, UserSettingsInit.Response ) -> Task Session.Error ( Session, Model )
buildModel ( session, { user } ) =
    let
        model =
            Model user.firstName user.lastName user.email
    in
        Task.succeed ( session, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    text ""
