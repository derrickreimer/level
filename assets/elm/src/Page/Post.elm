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
import Repo exposing (Repo)
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
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
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
        (NewRepo.getSpaceUser (SpaceUser.id model.viewer) repo)
        (NewRepo.getSpace (Space.id model.space) repo)
        (Just <| NewRepo.getGroups (List.map Group.id model.bookmarks) repo)



-- PAGE PROPERTIES


title : Repo -> Model -> String
title repo { viewer } =
    let
        userData =
            Repo.getSpaceUser repo viewer

        name =
            displayName userData
    in
    "View post from " ++ name


viewingTopic : Model -> String
viewingTopic { postComp } =
    "posts:" ++ postComp.id



-- LIFECYCLE


init : String -> String -> Globals -> Task Session.Error ( Globals, Model )
init spaceSlug postId globals =
    globals.session
        |> PostInit.request spaceSlug postId
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.andThen (buildModel globals)


buildModel : Globals -> ( ( Session, PostInit.Response ), ( Zone, Posix ) ) -> Task Session.Error ( Globals, Model )
buildModel globals ( ( newSession, resp ), now ) =
    let
        postComp =
            Component.Post.init Component.Post.FullPage True resp.post (Connection.map Reply.id resp.replies)

        model =
            Model resp.viewer resp.space resp.bookmarks postComp now NotLoaded

        newNewRepo =
            globals.newRepo
                |> NewRepo.setSpace resp.space
                |> NewRepo.setSpaceUser resp.viewer
                |> NewRepo.setGroups resp.bookmarks
                |> NewRepo.setPost resp.post
                |> NewRepo.setSpaceUser resp.author
                |> NewRepo.setReplies (Connection.toList resp.replies)

        newGlobals =
            { globals | session = newSession, newRepo = newNewRepo }
    in
    Task.succeed ( newGlobals, model )


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
recordView session { space, postComp } =
    let
        { nodes } =
            Connection.last 1 postComp.replyIds

        maybeReplyId =
            case nodes of
                [ lastReplyId ] ->
                    Just lastReplyId

                _ ->
                    Nothing
    in
    session
        |> RecordPostView.request (Space.id space) postComp.id maybeReplyId
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
                ( ( newPostComp, cmd ), newSession ) =
                    Component.Post.update componentMsg (Space.id model.space) globals.session model.postComp
            in
            ( ( { model | postComp = newPostComp }
              , Cmd.map PostComponentMsg cmd
              )
            , { globals | session = newSession }
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
                ( newRepo, newNewRepo ) =
                    case response of
                        GetSpaceUser.Success spaceUser ->
                            ( Repo.setSpaceUser globals.repo spaceUser
                            , NewRepo.setSpaceUser spaceUser globals.newRepo
                            )

                        _ ->
                            ( globals.repo, globals.newRepo )
            in
            noCmd { globals | session = newSession, repo = newRepo, newRepo = newNewRepo } model

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
            ( { model | bookmarks = insertUniqueBy Group.id group model.bookmarks }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarks = removeBy Group.id group model.bookmarks }, Cmd.none )

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
handleJoin presence { session, repo } model =
    case Repo.getSpaceUserByUserId repo (Presence.getUserId presence) of
        Just _ ->
            ( model, Cmd.none )

        Nothing ->
            ( model
            , session
                |> GetSpaceUser.request (Space.id model.space) (Presence.getUserId presence)
                |> Task.attempt SpaceUserFetched
            )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every 1000 Tick



-- VIEW


view : Repo -> NewRepo -> Maybe Route -> Model -> Html Msg
view repo newRepo maybeCurrentRoute model =
    case resolveData newRepo model of
        Just data ->
            resolvedView repo newRepo maybeCurrentRoute model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> NewRepo -> Maybe Route -> Model -> Data -> Html Msg
resolvedView repo newRepo maybeCurrentRoute model data =
    spaceLayout repo
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ postView repo newRepo data.space data.viewer model.now model.postComp
                , sidebarView newRepo model
                ]
            ]
        ]


postView : Repo -> NewRepo -> Space -> SpaceUser -> ( Zone, Posix ) -> Component.Post.Model -> Html Msg
postView repo newRepo space currentUser now component =
    div [ class "pt-6" ]
        [ Component.Post.view repo newRepo space currentUser now component
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
