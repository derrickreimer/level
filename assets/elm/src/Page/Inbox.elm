module Page.Inbox exposing (Model, Msg(..), handleMentionsDismissed, handleReplyCreated, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Data.Post as Post exposing (Post)
import Data.Reply as Reply exposing (Reply)
import Data.Space as Space exposing (Space)
import Data.SpaceUser as SpaceUser exposing (SpaceUser)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Query.InboxInit as InboxInit
import Repo exposing (Repo)
import Route
import Route.SpaceUsers
import Session exposing (Session)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import View.Helpers exposing (displayName, smartFormatDate)



-- MODEL


type alias Model =
    { space : Space
    , currentUser : SpaceUser
    , mentionedPosts : Connection Component.Post.Model
    , now : ( Zone, Posix )
    }



-- PAGE PROPERTIES


title : String
title =
    "Inbox"



-- LIFECYCLE


init : Space -> SpaceUser -> Session -> Task Session.Error ( Session, Model )
init space currentUser session =
    session
        |> InboxInit.request (Space.getId space)
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.andThen (buildModel space currentUser)


buildModel : Space -> SpaceUser -> ( ( Session, InboxInit.Response ), ( Zone, Posix ) ) -> Task Session.Error ( Session, Model )
buildModel space currentUser ( ( session, { mentionedPosts } ), now ) =
    Task.succeed ( session, Model space currentUser mentionedPosts now )


setup : Model -> Cmd Msg
setup model =
    let
        mentionsCmd =
            model.mentionedPosts
                |> Connection.toList
                |> List.map (\component -> Cmd.map (PostComponentMsg component.id) (Component.Post.setup component))
                |> Cmd.batch
    in
    mentionsCmd


teardown : Model -> Cmd Msg
teardown model =
    let
        mentionsCmd =
            model.mentionedPosts
                |> Connection.toList
                |> List.map (\component -> Cmd.map (PostComponentMsg component.id) (Component.Post.teardown component))
                |> Cmd.batch
    in
    mentionsCmd



-- UPDATE


type Msg
    = Tick Posix
    | SetCurrentTime Posix Zone
    | PostComponentMsg String Component.Post.Msg


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), session )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
                |> noCmd session

        PostComponentMsg id componentMsg ->
            case Connection.get .id id model.mentionedPosts of
                Just component ->
                    let
                        ( ( newComponent, cmd ), newSession ) =
                            Component.Post.update componentMsg (Space.getId model.space) session component
                    in
                    ( ( { model | mentionedPosts = Connection.update .id newComponent model.mentionedPosts }
                      , Cmd.map (PostComponentMsg id) cmd
                      )
                    , newSession
                    )

                Nothing ->
                    noCmd session model


noCmd : Session -> Model -> ( ( Model, Cmd Msg ), Session )
noCmd session model =
    ( ( model, Cmd.none ), session )



-- EVENT HANDLERS


handleReplyCreated : Reply -> Model -> ( Model, Cmd Msg )
handleReplyCreated reply ({ mentionedPosts } as model) =
    let
        id =
            Reply.getPostId reply
    in
    case Connection.get .id id mentionedPosts of
        Just component ->
            let
                ( newComponent, cmd ) =
                    Component.Post.handleReplyCreated reply component
            in
            ( { model | mentionedPosts = Connection.update .id newComponent mentionedPosts }
            , Cmd.map (PostComponentMsg id) cmd
            )

        Nothing ->
            ( model, Cmd.none )


handleMentionsDismissed : Post -> Model -> ( Model, Cmd Msg )
handleMentionsDismissed post ({ mentionedPosts } as model) =
    let
        id =
            Post.getId post
    in
    case Connection.get .id id mentionedPosts of
        Just component ->
            ( { model | mentionedPosts = Connection.remove .id id mentionedPosts }
            , Cmd.map (PostComponentMsg id) (Component.Post.teardown component)
            )

        Nothing ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    every 1000 Tick



-- VIEW


view : Repo -> List SpaceUser -> Model -> Html Msg
view repo featuredUsers model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ div [ class "sticky pin-t border-b mb-3 py-4 bg-white z-50" ]
                [ div [ class "flex items-center" ]
                    [ h2 [ class "font-extrabold text-2xl" ] [ text "Inbox" ]
                    ]
                ]
            , mentionsView repo model
            , sidebarView repo featuredUsers
            ]
        ]


mentionsView : Repo -> Model -> Html Msg
mentionsView repo model =
    div [] <|
        Connection.map (postView repo model) model.mentionedPosts


postView : Repo -> Model -> Component.Post.Model -> Html Msg
postView repo model component =
    div [ class "py-4 flex" ]
        [ div [ class "mr-1 py-2 flex-0" ]
            [ label [ class "control checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , class "checkbox"
                    ]
                    []
                , span [ class "control-indicator border-dusty-blue" ] []
                ]
            ]
        , div [ class "flex-1" ]
            [ component
                |> Component.Post.postView repo model.currentUser model.now
                |> Html.map (PostComponentMsg component.id)
            ]
        ]


sidebarView : Repo -> List SpaceUser -> Html Msg
sidebarView repo featuredUsers =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ]
            [ a
                [ Route.href (Route.SpaceUsers Route.SpaceUsers.Root)
                , class "flex items-center text-dusty-blue-darkest no-underline"
                ]
                [ span [ class "mr-2" ] [ text "Directory" ]
                , Icons.arrowUpRight
                ]
            ]
        , div [ class "pb-4" ] <| List.map (userItemView repo) featuredUsers
        , a
            [ Route.href Route.SpaceSettings
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
