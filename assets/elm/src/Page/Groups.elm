module Page.Groups
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
import Connection exposing (Connection)
import Data.Group as Group exposing (Group)
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Query.GroupsInit as GroupsInit
import Repo exposing (Repo)
import Route
import Session exposing (Session)


-- MODEL


type alias Model =
    { space : Space
    , user : SpaceUser
    , groups : Connection Group
    }



-- LIFECYCLE


init : SpaceUser -> Space -> Session -> Task Session.Error ( Session, Model )
init user space session =
    session
        |> GroupsInit.request (Space.getId space) Nothing 10
        |> Task.andThen (buildModel user space)


buildModel : SpaceUser -> Space -> ( Session, GroupsInit.Response ) -> Task Session.Error ( Session, Model )
buildModel user space ( session, { groups } ) =
    Task.succeed ( session, Model space user groups )


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
    ( ( model, Cmd.none ), session )



-- VIEW


view : Repo -> Model -> Html Msg
view repo model =
    div [ class "ml-56 mr-24" ]
        [ div [ class "mx-auto max-w-md leading-normal py-8" ]
            [ h1 [ class "pb-8 font-extrabold text-3xl" ] [ text "Group Directory" ]
            , groupsView repo model.groups
            ]
        ]


groupsView : Repo -> Connection Group -> Html Msg
groupsView repo connection =
    div [ class "leading-semi-loose" ] <|
        Connection.map (groupView repo) connection


groupView : Repo -> Group -> Html Msg
groupView repo group =
    let
        groupData =
            Repo.getGroup repo group
    in
        div []
            [ h2 [ class "font-normal text-lg" ]
                [ a [ Route.href (Route.Group groupData.id), class "text-blue no-underline" ] [ text groupData.name ]
                ]
            ]
