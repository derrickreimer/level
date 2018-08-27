module Page.Inbox exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Event exposing (Event)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import ListHelpers exposing (insertUniqueBy, removeBy)
import Post exposing (Post)
import Query.InboxInit as InboxInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.SpaceUsers
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import View.Helpers exposing (displayName, smartFormatDate, viewIf)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    , mentions : Connection Component.Post.Model
    , now : ( Zone, Posix )
    }



-- PAGE PROPERTIES


title : String
title =
    "Inbox"



-- LIFECYCLE


init : String -> Session -> Task Session.Error ( Session, Model )
init spaceSlug session =
    session
        |> InboxInit.request spaceSlug
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.andThen buildModel


buildModel : ( ( Session, InboxInit.Response ), ( Zone, Posix ) ) -> Task Session.Error ( Session, Model )
buildModel ( ( session, { viewer, space, bookmarks, featuredUsers, mentions } ), now ) =
    Task.succeed ( session, Model viewer space bookmarks featuredUsers mentions now )


setup : Model -> Cmd Msg
setup model =
    let
        mentionsCmd =
            model.mentions
                |> Connection.toList
                |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.setup c))
                |> Cmd.batch
    in
    mentionsCmd


teardown : Model -> Cmd Msg
teardown model =
    let
        mentionsCmd =
            model.mentions
                |> Connection.toList
                |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.teardown c))
                |> Cmd.batch
    in
    mentionsCmd



-- UPDATE


type Msg
    = Tick Posix
    | SetCurrentTime Posix Zone
    | PostComponentMsg String Component.Post.Msg
    | DismissSelected


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), session )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
                |> noCmd session

        PostComponentMsg id componentMsg ->
            case Connection.get .id id model.mentions of
                Just component ->
                    let
                        ( ( newComponent, cmd ), newSession ) =
                            Component.Post.update componentMsg (Space.getId model.space) session component
                    in
                    ( ( { model | mentions = Connection.update .id newComponent model.mentions }
                      , Cmd.map (PostComponentMsg id) cmd
                      )
                    , newSession
                    )

                Nothing ->
                    noCmd session model

        DismissSelected ->
            -- TODO
            noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarks = insertUniqueBy Group.getId group model.bookmarks }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarks = removeBy Group.getId group model.bookmarks }, Cmd.none )

        Event.ReplyCreated reply ->
            let
                postId =
                    Reply.getPostId reply
            in
            case Connection.get .id postId model.mentions of
                Just component ->
                    let
                        ( newComponent, cmd ) =
                            Component.Post.handleReplyCreated reply component
                    in
                    ( { model | mentions = Connection.update .id newComponent model.mentions }
                    , Cmd.map (PostComponentMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        Event.MentionsDismissed post ->
            let
                postId =
                    Post.getId post
            in
            case Connection.get .id postId model.mentions of
                Just component ->
                    ( { model | mentions = Connection.remove .id postId model.mentions }
                    , Cmd.map (PostComponentMsg postId) (Component.Post.teardown component)
                    )

                Nothing ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every 1000 Tick



-- VIEW


view : Repo -> Maybe Route -> Model -> Html Msg
view repo maybeCurrentRoute model =
    spaceLayout repo
        model.viewer
        model.space
        model.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ div [ class "sticky pin-t border-b mb-3 py-4 bg-white z-50" ]
                    [ div [ class "flex items-center" ]
                        [ h2 [ class "flex-no-shrink font-extrabold text-2xl" ] [ text "Inbox" ]
                        , controlsView model
                        ]
                    ]
                , mentionsView repo model
                , sidebarView repo model.space model.featuredUsers
                ]
            ]
        ]


controlsView : Model -> Html Msg
controlsView model =
    div [ class "flex flex-grow justify-end" ]
        [ viewIf (arePostsSelected model.mentions) <|
            button [ class "btn btn-xs btn-turquoise-outline", onClick DismissSelected ] [ text "Dismiss" ]
        ]


mentionsView : Repo -> Model -> Html Msg
mentionsView repo model =
    div [] <|
        Connection.mapList (postView repo model) model.mentions


postView : Repo -> Model -> Component.Post.Model -> Html Msg
postView repo model component =
    div [ class "py-4" ]
        [ component
            |> Component.Post.checkableView repo model.space model.viewer model.now
            |> Html.map (PostComponentMsg component.id)
        ]


sidebarView : Repo -> Space -> List SpaceUser -> Html Msg
sidebarView repo space featuredUsers =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ]
            [ a
                [ Route.href (Route.SpaceUsers <| Route.SpaceUsers.Root (Space.getSlug space))
                , class "flex items-center text-dusty-blue-darkest no-underline"
                ]
                [ span [ class "mr-2" ] [ text "Directory" ]
                , Icons.arrowUpRight
                ]
            ]
        , div [ class "pb-4" ] <| List.map (userItemView repo) featuredUsers
        , a
            [ Route.href (Route.SpaceSettings (Space.getSlug space))
            , class "text-sm text-blue no-underline"
            ]
            [ text "Space Settings" ]
        ]


userItemView : Repo -> SpaceUser -> Html Msg
userItemView repo user =
    let
        userData =
            user
                |> Repo.getSpaceUser repo
    in
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny userData ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| displayName userData ]
        ]



-- INTERNAL


arePostsSelected : Connection Component.Post.Model -> Bool
arePostsSelected posts =
    posts
        |> Connection.toList
        |> List.any .isChecked
