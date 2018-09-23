module Page.Inbox exposing (Model, Msg(..), consumeEvent, init, setup, subscriptions, teardown, title, update, view)

import Avatar exposing (personAvatar)
import Component.Post
import Connection exposing (Connection)
import Event exposing (Event)
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import KeyboardShortcuts
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.DismissPosts as DismissPosts
import NewRepo exposing (NewRepo)
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
    , viewerId : Id
    , spaceId : Id
    , bookmarkIds : List Id
    , featuredUserIds : List Id
    , postComps : Connection Component.Post.Model
    , now : ( Zone, Posix )
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , featuredUsers : List SpaceUser
    }


resolveData : NewRepo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (NewRepo.getSpaceUser model.viewerId repo)
        (NewRepo.getSpace model.spaceId repo)
        (Just <| NewRepo.getGroups model.bookmarkIds repo)
        (Just <| NewRepo.getSpaceUsers model.featuredUserIds repo)



-- PAGE PROPERTIES


title : String
title =
    "Inbox"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> InboxInit.request params
        |> TaskHelpers.andThenGetCurrentTime
        |> Task.map (buildModel globals params)


buildModel : Globals -> Params -> ( ( Session, InboxInit.Response ), ( Zone, Posix ) ) -> ( Globals, Model )
buildModel globals params ( ( newSession, resp ), now ) =
    let
        postComps =
            Connection.map buildPostComponent resp.postWithRepliesIds

        newGlobals =
            { globals
                | session = newSession
                , newRepo = NewRepo.union resp.repo globals.newRepo
            }
    in
    ( newGlobals
    , Model
        params
        resp.viewerId
        resp.spaceId
        resp.bookmarkIds
        resp.featuredUserIds
        postComps
        now
    )


buildPostComponent : ( Id, Connection Id ) -> Component.Post.Model
buildPostComponent ( postId, replyIds ) =
    Component.Post.init
        Component.Post.Feed
        True
        postId
        replyIds


setup : Model -> Cmd Msg
setup model =
    let
        postsCmd =
            model.postComps
                |> Connection.toList
                |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.setup c))
                |> Cmd.batch
    in
    postsCmd


teardown : Model -> Cmd Msg
teardown model =
    let
        postsCmd =
            model.postComps
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


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        Tick posix ->
            ( ( model, Task.perform (SetCurrentTime posix) Time.here ), globals )

        SetCurrentTime posix zone ->
            { model | now = ( zone, posix ) }
                |> noCmd globals

        PostComponentMsg id componentMsg ->
            case Connection.get .id id model.postComps of
                Just component ->
                    let
                        ( ( newComponent, cmd ), newGlobals ) =
                            Component.Post.update componentMsg model.spaceId globals component
                    in
                    ( ( { model | postComps = Connection.update .id newComponent model.postComps }
                      , Cmd.map (PostComponentMsg id) cmd
                      )
                    , newGlobals
                    )

                Nothing ->
                    noCmd globals model

        DismissPostsClicked ->
            let
                postIds =
                    model.postComps
                        |> filterBySelected
                        |> List.map .id

                cmd =
                    globals.session
                        |> DismissPosts.request model.spaceId postIds
                        |> Task.attempt PostsDismissed
            in
            if List.isEmpty postIds then
                noCmd globals model

            else
                ( ( model, cmd ), globals )

        PostsDismissed _ ->
            noCmd globals model

        PushSubscribeClicked ->
            ( ( model, PushManager.subscribe ), globals )

        NoOp ->
            noCmd globals model


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )



-- EVENTS


consumeEvent : Event -> Model -> ( Model, Cmd Msg )
consumeEvent event model =
    case event of
        Event.GroupBookmarked group ->
            ( { model | bookmarkIds = insertUniqueBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.GroupUnbookmarked group ->
            ( { model | bookmarkIds = removeBy identity (Group.id group) model.bookmarkIds }, Cmd.none )

        Event.ReplyCreated reply ->
            let
                postId =
                    Reply.postId reply
            in
            case Connection.get .id postId model.postComps of
                Just component ->
                    let
                        ( newComponent, cmd ) =
                            Component.Post.handleReplyCreated reply component
                    in
                    ( { model | postComps = Connection.update .id newComponent model.postComps }
                    , Cmd.map (PostComponentMsg postId) cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        Event.PostsDismissed posts ->
            let
                remove post ( components, cmds ) =
                    let
                        postId =
                            Post.id post
                    in
                    case Connection.get .id postId components of
                        Just component ->
                            ( Connection.remove .id postId components
                            , Cmd.map (PostComponentMsg postId) (Component.Post.teardown component) :: cmds
                            )

                        Nothing ->
                            ( components, cmds )

                ( newPostComps, teardownCmds ) =
                    List.foldr remove ( model.postComps, [] ) posts
            in
            ( { model | postComps = newPostComps }, Cmd.batch teardownCmds )

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


view : NewRepo -> Maybe Route -> Bool -> Model -> Html Msg
view newRepo maybeCurrentRoute hasPushSubscription model =
    case resolveData newRepo model of
        Just data ->
            resolvedView newRepo maybeCurrentRoute hasPushSubscription model data

        Nothing ->
            text "Something went wrong."


resolvedView : NewRepo -> Maybe Route -> Bool -> Model -> Data -> Html Msg
resolvedView newRepo maybeCurrentRoute hasPushSubscription model data =
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ div [ class "sticky pin-t border-b mb-3 py-4 bg-white z-50" ]
                    [ div [ class "flex items-center" ]
                        [ h2 [ class "flex-no-shrink font-extrabold text-2xl" ] [ text "Inbox" ]
                        , controlsView model data
                        ]
                    ]
                , postsView newRepo model data
                , sidebarView data.space data.featuredUsers hasPushSubscription
                ]
            ]
        ]


controlsView : Model -> Data -> Html Msg
controlsView model data =
    div [ class "flex flex-grow justify-end" ]
        [ selectionControlsView model.postComps
        , paginationView data.space model.postComps
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
        (Route.Inbox << Before (Space.slug space))
        (Route.Inbox << After (Space.slug space))


postsView : NewRepo -> Model -> Data -> Html Msg
postsView newRepo model data =
    if Connection.isEmptyAndExpanded model.postComps then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "You're all caught up!" ]

    else
        div [] <|
            Connection.mapList (postView newRepo model data) model.postComps


postView : NewRepo -> Model -> Data -> Component.Post.Model -> Html Msg
postView newRepo model data component =
    div [ class "py-4" ]
        [ component
            |> Component.Post.checkableView newRepo data.space data.viewer model.now
            |> Html.map (PostComponentMsg component.id)
        ]


sidebarView : Space -> List SpaceUser -> Bool -> Html Msg
sidebarView space featuredUsers hasPushSubscription =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ]
            [ a
                [ Route.href (Route.SpaceUsers <| Route.SpaceUsers.Root (Space.slug space))
                , class "flex items-center text-dusty-blue-darkest no-underline"
                ]
                [ text "Directory"
                ]
            ]
        , div [ class "pb-4" ] <| List.map userItemView featuredUsers
        , viewUnless hasPushSubscription <|
            button
                [ class "block text-sm text-blue"
                , onClick PushSubscribeClicked
                ]
                [ text "Enable notifications" ]
        , a
            [ Route.href (Route.SpaceSettings (Space.slug space))
            , class "text-sm text-blue no-underline"
            ]
            [ text "Space settings" ]
        ]


userItemView : SpaceUser -> Html Msg
userItemView user =
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ SpaceUser.avatar Avatar.Tiny user ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| SpaceUser.displayName user ]
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
