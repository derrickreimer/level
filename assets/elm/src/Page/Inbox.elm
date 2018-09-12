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
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import KeyboardShortcuts
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.DismissPosts as DismissPosts
import Pagination
import Post exposing (Post)
import PushManager
import Query.InboxInit as InboxInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Inbox exposing (Params(..))
import Route.SpaceUsers
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import View.Helpers exposing (displayName, smartFormatTime, viewIf, viewUnless)
import View.Layout exposing (spaceLayout)



-- MODEL


type alias Model =
    { params : Params
    , viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    , posts : Connection Component.Post.Model
    , now : ( Zone, Posix )
    }



-- PAGE PROPERTIES


title : String
title =
    "Inbox"



-- LIFECYCLE


init : Params -> Session -> Task Session.Error ( Session, Model )
init params session =
    session
        |> InboxInit.request params
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.andThen (buildModel params)


buildModel : Params -> ( ( Session, InboxInit.Response ), ( Zone, Posix ) ) -> Task Session.Error ( Session, Model )
buildModel params ( ( session, { viewer, space, bookmarks, featuredUsers, posts } ), now ) =
    Task.succeed ( session, Model params viewer space bookmarks featuredUsers posts now )


setup : Model -> Cmd Msg
setup model =
    let
        postsCmd =
            model.posts
                |> Connection.toList
                |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.setup c))
                |> Cmd.batch
    in
    postsCmd


teardown : Model -> Cmd Msg
teardown model =
    let
        postsCmd =
            model.posts
                |> Connection.toList
                |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.teardown c))
                |> Cmd.batch
    in
    postsCmd



-- UPDATE


type Msg
    = Tick Posix
    | SetCurrentTime Posix Zone
    | PostComponentMsg String Component.Post.Msg
    | DismissPostsClicked
    | PostsDismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | PushSubscribeClicked
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), Session )
update msg session model =
    case msg of
        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), session )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
                |> noCmd session

        PostComponentMsg id componentMsg ->
            case Connection.get .id id model.posts of
                Just component ->
                    let
                        ( ( newComponent, cmd ), newSession ) =
                            Component.Post.update componentMsg (Space.getId model.space) session component
                    in
                    ( ( { model | posts = Connection.update .id newComponent model.posts }
                      , Cmd.map (PostComponentMsg id) cmd
                      )
                    , newSession
                    )

                Nothing ->
                    noCmd session model

        DismissPostsClicked ->
            let
                postIds =
                    model.posts
                        |> filterBySelected
                        |> List.map .id

                cmd =
                    session
                        |> DismissPosts.request (Space.getId model.space) postIds
                        |> Task.attempt PostsDismissed
            in
            if List.isEmpty postIds then
                noCmd session model

            else
                ( ( model, cmd ), session )

        PostsDismissed _ ->
            noCmd session model

        PushSubscribeClicked ->
            ( ( model, PushManager.subscribe ), session )

        NoOp ->
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
            case Connection.get .id postId model.posts of
                Just component ->
                    let
                        ( newComponent, cmd ) =
                            Component.Post.handleReplyCreated reply component
                    in
                    ( { model | posts = Connection.update .id newComponent model.posts }
                    , Cmd.map (PostComponentMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        Event.PostsDismissed posts ->
            let
                remove post ( components, cmds ) =
                    let
                        postId =
                            Post.getId post
                    in
                    case Connection.get .id postId components of
                        Just component ->
                            ( Connection.remove .id postId components
                            , Cmd.map (PostComponentMsg postId) (Component.Post.teardown component) :: cmds
                            )

                        Nothing ->
                            ( components, cmds )

                ( newPosts, teardownCmds ) =
                    List.foldr remove ( model.posts, [] ) posts
            in
            ( { model | posts = newPosts }, Cmd.batch teardownCmds )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ every 1000 Tick
        , KeyboardShortcuts.subscribe
            [ ( "y", DismissPostsClicked )
            ]
        ]



-- VIEW


view : Repo -> Maybe Route -> Bool -> Model -> Html Msg
view repo maybeCurrentRoute hasPushSubscription model =
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
                , postsView repo model
                , sidebarView repo model.space model.featuredUsers hasPushSubscription
                ]
            ]
        ]


controlsView : Model -> Html Msg
controlsView model =
    div [ class "flex flex-grow justify-end" ]
        [ selectionControlsView model.posts
        , paginationView model.space model.posts
        ]


selectionControlsView : Connection Component.Post.Model -> Html Msg
selectionControlsView posts =
    let
        selectedPosts =
            filterBySelected posts
    in
    if List.isEmpty selectedPosts then
        text ""

    else
        div []
            [ selectedLabel selectedPosts
            , button [ class "mr-4 btn btn-xs btn-blue", onClick DismissPostsClicked ] [ text "Dismiss" ]
            ]


paginationView : Space -> Connection a -> Html Msg
paginationView space connection =
    Pagination.view connection
        (Route.Inbox << Before (Space.getSlug space))
        (Route.Inbox << After (Space.getSlug space))


postsView : Repo -> Model -> Html Msg
postsView repo model =
    if Connection.isEmptyAndExpanded model.posts then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "You're all caught up!" ]

    else
        div [] <|
            Connection.mapList (postView repo model) model.posts


postView : Repo -> Model -> Component.Post.Model -> Html Msg
postView repo model component =
    div [ class "py-4" ]
        [ component
            |> Component.Post.checkableView repo model.space model.viewer model.now
            |> Html.map (PostComponentMsg component.id)
        ]


sidebarView : Repo -> Space -> List SpaceUser -> Bool -> Html Msg
sidebarView repo space featuredUsers hasPushSubscription =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ]
            [ a
                [ Route.href (Route.SpaceUsers <| Route.SpaceUsers.Root (Space.getSlug space))
                , class "flex items-center text-dusty-blue-darkest no-underline"
                ]
                [ text "Directory"
                ]
            ]
        , div [ class "pb-4" ] <| List.map (userItemView repo) featuredUsers
        , viewUnless hasPushSubscription <|
            button
                [ class "block text-sm text-blue"
                , onClick PushSubscribeClicked
                ]
                [ text "Enable notifications" ]
        , a
            [ Route.href (Route.SpaceSettings (Space.getSlug space))
            , class "text-sm text-blue no-underline"
            ]
            [ text "Space settings" ]
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


filterBySelected : Connection Component.Post.Model -> List Component.Post.Model
filterBySelected posts =
    posts
        |> Connection.toList
        |> List.filter .isChecked


selectedLabel : List a -> Html Msg
selectedLabel list =
    let
        count =
            List.length list

        target =
            pluralize count "post" "posts"
    in
    span [ class "mr-2 text-sm text-dusty-blue" ]
        [ text <| String.fromInt count ++ " " ++ target ++ " selected" ]


pluralize : Int -> String -> String -> String
pluralize count singular plural =
    if count == 1 then
        singular

    else
        plural
