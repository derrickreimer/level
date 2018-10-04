module Page.Setup.InviteUsers exposing (ExternalMsg(..), Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Clipboard
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Id exposing (Id)
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CompleteSetupStep as CompleteSetupStep
import Query.SetupInit as SetupInit
import Repo exposing (Repo)
import Route exposing (Route)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import View.SpaceLayout



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


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)



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

        repo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = repo }, model )


setup : Model -> Cmd Msg
setup model =
    Scroll.toDocumentTop InternalNoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = Submit
    | Advanced (Result Session.Error ( Session, CompleteSetupStep.Response ))
    | InternalNoOp


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
            ( ( model, Cmd.none )
            , { globals | session = newSession }
            , SetupStateChanged nextState
            )

        Advanced (Err Session.Expired) ->
            redirectToLogin globals model

        Advanced (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals, NoOp )

        InternalNoOp ->
            ( ( model, Cmd.none ), globals, NoOp )


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


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    case resolveData repo model of
        Just data ->
            resolvedView maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Maybe Route -> Model -> Data -> Html Msg
resolvedView maybeCurrentRoute model data =
    View.SpaceLayout.layout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-auto px-8 py-24 max-w-sm leading-normal" ]
            [ h2 [ class "mb-6 font-extrabold text-3xl" ] [ text "Invite your colleagues" ]
            , bodyView (Space.openInvitationUrl data.space) model
            ]
        ]


bodyView : Maybe String -> Model -> Html Msg
bodyView maybeUrl model =
    case maybeUrl of
        Just url ->
            div []
                [ p [ class "mb-6" ] [ text "The best way to try out Level is with other people! Anyone with this link can join the space:" ]
                , div [ class "mb-4 flex items-center input-field py-2" ]
                    [ span [ class "mr-4 flex-shrink font-mono text-sm overflow-auto" ] [ text url ]
                    , Clipboard.button "Copy" url [ class "btn btn-blue btn-xs flex items-center" ]
                    ]
                , button [ class "btn btn-blue", onClick Submit, disabled model.isSubmitting ] [ text "Next step" ]
                ]

        Nothing ->
            div []
                [ p [ class "mb-6" ] [ text "Open invitations are disabled." ]
                , button [ class "btn btn-blue", onClick Submit, disabled model.isSubmitting ] [ text "Next step" ]
                ]
