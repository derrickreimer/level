module Page.Post exposing (Model, Msg(..), consumeEvent, init, receivePresence, setup, subscriptions, teardown, title, update, view)

import Component.Post
import Connection
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Lazy exposing (Lazy(..))
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.RecordPostView as RecordPostView
import NewRepo exposing (NewRepo)
import Post
import Presence exposing (Presence, PresenceList)
import Query.GetSpaceUser as GetSpaceUser
import Query.PostInit as PostInit
import Reply exposing (Reply)
import Route exposing (Route)
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import View.Helpers exposing (displayName)
import View.Layout exposing (spaceLayout)
import View.PresenceList



-- MODEL


type alias Model =
    { viewerId : String
    , spaceId : String
    , bookmarkIds : List String
    , postComp : Component.Post.Model
    , now : ( Zone, Posix )
    , currentViewers : Lazy PresenceList
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


title : Model -> String
title model =
    "View post"


viewingTopic : Model -> String
viewingTopic { postComp } =
    "posts:" ++ postComp.id



-- LIFECYCLE


init : String -> String -> Globals -> Task Session.Error ( Globals, Model )
init spaceSlug postId globals =
    globals.session
        |> PostInit.request spaceSlug postId
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.map (buildModel globals)


buildModel : Globals -> ( ( Session, PostInit.Response ), ( Zone, Posix ) ) -> ( Globals, Model )
buildModel globals ( ( newSession, resp ), now ) =
    let
        postComp =
            Component.Post.init
                Component.Post.FullPage
                True
                resp.postId
                resp.replyIds

        model =
            Model
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                postComp
                now
                NotLoaded

        newNewRepo =
            NewRepo.union resp.repo globals.newRepo

        newGlobals =
            { globals | session = newSession, newRepo = newNewRepo }
    in
    ( newGlobals, model )


setup : Globals -> Model -> Cmd Msg
setup globals ({ postComp } as model) =
    Cmd.batch
        [ Cmd.map PostComponentMsg (Component.Post.setup postComp)
        , recordView globals.session model
        , Presence.join (viewingTopic model)
        ]


teardown : Model -> Cmd Msg
teardown ({ postComp } as model) =
    Cmd.batch
        [ Cmd.map PostComponentMsg (Component.Post.teardown postComp)
        , Presence.leave (viewingTopic model)
        ]


recordView : Session -> Model -> Cmd Msg
recordView session model =
    let
        { nodes } =
            Connection.last 1 model.postComp.replyIds

        maybeReplyId =
            case nodes of
                [ lastReplyId ] ->
                    Just lastReplyId

                _ ->
                    Nothing
    in
    session
        |> RecordPostView.request model.spaceId model.postComp.id maybeReplyId
        |> Task.attempt ViewRecorded



-- UPDATE


type Msg
    = PostComponentMsg Component.Post.Msg
    | ViewRecorded (Result Session.Error ( Session, RecordPostView.Response ))
    | Tick Posix
    | SetCurrentTime Posix Zone
    | SpaceUserFetched (Result Session.Error ( Session, GetSpaceUser.Response ))
    | NoOp


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        PostComponentMsg componentMsg ->
            let
                ( ( newPostComp, cmd ), newGlobals ) =
                    Component.Post.update componentMsg model.spaceId globals model.postComp
            in
            ( ( { model | postComp = newPostComp }
              , Cmd.map PostComponentMsg cmd
              )
            , newGlobals
            )

        ViewRecorded (Ok ( newSession, _ )) ->
            noCmd { globals | session = newSession } model

        ViewRecorded (Err Session.Expired) ->
            redirectToLogin globals model

        ViewRecorded (Err _) ->
            noCmd globals model

        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), globals )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
                |> noCmd globals

        SpaceUserFetched (Ok ( newSession, response )) ->
            let
                newNewRepo =
                    case response of
                        GetSpaceUser.Success spaceUser ->
                            NewRepo.setSpaceUser spaceUser globals.newRepo

                        _ ->
                            globals.newRepo
            in
            noCmd { globals | session = newSession, newRepo = newNewRepo } model

        SpaceUserFetched (Err Session.Expired) ->
            redirectToLogin globals model

        SpaceUserFetched (Err _) ->
            noCmd globals model

        NoOp ->
            noCmd globals model


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



-- INBOUND EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.ReplyCreated reply ->
            let
                ( newPostComp, cmd ) =
                    Component.Post.handleReplyCreated reply model.postComp
            in
            ( { model | postComp = newPostComp }
            , Cmd.map PostComponentMsg cmd
            )

        _ ->
            ( model, Cmd.none )


receivePresence : Presence.Event -> Globals -> Model -> ( Model, Cmd Msg )
receivePresence event globals model =
    case event of
        Presence.Sync topic list ->
            if topic == viewingTopic model then
                handleSync list model

            else
                ( model, Cmd.none )

        Presence.Join topic presence ->
            if topic == viewingTopic model then
                handleJoin presence globals model

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


handleSync : PresenceList -> Model -> ( Model, Cmd Msg )
handleSync list model =
    ( { model | currentViewers = Loaded list }, Cmd.none )


handleJoin : Presence -> Globals -> Model -> ( Model, Cmd Msg )
handleJoin presence globals model =
    case NewRepo.getSpaceUserByUserId (Presence.getUserId presence) globals.newRepo of
        Just _ ->
            ( model, Cmd.none )

        Nothing ->
            ( model
            , globals.session
                |> GetSpaceUser.request model.spaceId (Presence.getUserId presence)
                |> Task.attempt SpaceUserFetched
            )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every 1000 Tick



-- VIEW


view : NewRepo -> Maybe Route -> Model -> Html Msg
view newRepo maybeCurrentRoute model =
    case resolveData newRepo model of
        Just data ->
            resolvedView newRepo maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : NewRepo -> Maybe Route -> Model -> Data -> Html Msg
resolvedView newRepo maybeCurrentRoute model data =
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ postView newRepo data.space data.viewer model.now model.postComp
                , sidebarView newRepo model
                ]
            ]
        ]


postView : NewRepo -> Space -> SpaceUser -> ( Zone, Posix ) -> Component.Post.Model -> Html Msg
postView newRepo space currentUser now component =
    div [ class "pt-6" ]
        [ Component.Post.view newRepo space currentUser now component
            |> Html.map PostComponentMsg
        ]


sidebarView : NewRepo -> Model -> Html Msg
sidebarView repo model =
    let
        listView =
            case model.currentViewers of
                Loaded state ->
                    View.PresenceList.view repo state

                NotLoaded ->
                    div [ class "pb-4 text-sm" ] [ text "Loading..." ]
    in
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 px-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ] [ text "Who’s Here" ]
        , listView
        ]
