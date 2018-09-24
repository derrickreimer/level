module Page.Setup.InviteUsers exposing (ExternalMsg(..), Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CompleteSetupStep as CompleteSetupStep
import NewRepo exposing (NewRepo)
import Query.SetupInit as SetupInit
import Route exposing (Route)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { spaceSlug : String
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , isSubmitting : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    }


resolveData : NewRepo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (NewRepo.getSpaceUser model.viewerId repo)
        (NewRepo.getSpace model.spaceId repo)
        (Just <| NewRepo.getGroups model.bookmarkIds repo)



-- PAGE PROPERTIES


title : String
title =
    "Invite your colleagues"



-- LIFECYCLE


init : String -> Globals -> Task Session.Error ( Globals, Model )
init spaceSlug globals =
    globals.session
        |> SetupInit.request spaceSlug
        |> Task.map (buildModel spaceSlug globals)


buildModel : String -> Globals -> ( Session, SetupInit.Response ) -> ( Globals, Model )
buildModel spaceSlug globals ( newSession, resp ) =
    let
        model =
            Model
                spaceSlug
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                False

        newNewRepo =
            NewRepo.union resp.repo globals.newRepo
    in
    ( { globals | session = newSession, newRepo = newNewRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Cmd.none


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = Submit
    | Advanced (Result Session.Error ( Session, CompleteSetupStep.Response ))


type ExternalMsg
    = SetupStateChanged Space.SetupState
    | NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals, ExternalMsg )
update msg globals model =
    case msg of
        Submit ->
            let
                cmd =
                    globals.session
                        |> CompleteSetupStep.request model.spaceId Space.InviteUsers False
                        |> Task.attempt Advanced
            in
            ( ( { model | isSubmitting = True }, cmd ), globals, NoOp )

        Advanced (Ok ( newSession, CompleteSetupStep.Success nextState )) ->
            -- TODO: Re-instate navigation to next state
            ( ( model, Cmd.none )
            , { globals | session = newSession }
            , SetupStateChanged nextState
            )

        Advanced (Err Session.Expired) ->
            redirectToLogin globals model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals, NoOp )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals, ExternalMsg )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals, NoOp )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : NewRepo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    case resolveData repo model of
        Just data ->
            resolvedView maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Maybe Route -> Model -> Data -> Html Msg
resolvedView maybeCurrentRoute model data =
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto py-24 max-w-400px leading-normal" ]
                [ h2 [ class "mb-6 font-extrabold text-3xl" ] [ text "Invite your colleagues" ]
                , bodyView (Space.openInvitationUrl data.space)
                , button [ class "btn btn-blue", onClick Submit, disabled model.isSubmitting ]
                    [ text "Next step" ]
                ]
            ]
        ]


bodyView : Maybe String -> Html Msg
bodyView maybeUrl =
    case maybeUrl of
        Just url ->
            div []
                [ p [ class "mb-6" ] [ text "The best way to try out Level is with other people! Anyone with this link can join the space:" ]
                , input [ class "mb-6 input-field font-mono text-sm", value url ] []
                ]

        Nothing ->
            p [ class "mb-6" ] [ text "Open invitations are disabled." ]
