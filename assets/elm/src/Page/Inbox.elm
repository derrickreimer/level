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
import Pagination
import Post exposing (Post)
import PushManager
import Query.InboxInit as InboxInit
import Reply exposing (Reply)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Inbox exposing (Params(..))
import Route.SpaceUsers
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import TaskHelpers
import Time exposing (Posix, Zone, every)
import View.Helpers exposing (smartFormatTime, viewIf, viewUnless)
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


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)
        (Just <| Repo.getSpaceUsers model.featuredUserIds repo)



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
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( ( Session, InboxInit.Response ), ( Zone, Posix ) ) -> ( Globals, Model )
buildModel params globals ( ( newSession, resp ), now ) =
    let
        postComps =
            Connection.map buildPostComponent resp.postWithRepliesIds

        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.bookmarkIds
                resp.featuredUserIds
                postComps
                now

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


buildPostComponent : ( Id, Connection Id ) -> Component.Post.Model
buildPostComponent ( postId, replyIds ) =
    Component.Post.init Component.Post.Feed True postId replyIds


setup : Model -> Cmd Msg
setup model =
    let
        postsCmd =
            model.postComps
                |> Connection.toList
                |> setupPostComps
    in
    Cmd.batch
        [ postsCmd
        , Scroll.toDocumentTop NoOp
        ]


teardown : Model -> Cmd Msg
teardown model =
    let
        postsCmd =
            model.postComps
                |> Connection.toList
                |> teardownPostComps
    in
    postsCmd


setupPostComps : List Component.Post.Model -> Cmd Msg
setupPostComps comps =
    comps
        |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.setup c))
        |> Cmd.batch


teardownPostComps : List Component.Post.Model -> Cmd Msg
teardownPostComps comps =
    comps
        |> List.map (\c -> Cmd.map (PostComponentMsg c.id) (Component.Post.teardown c))
        |> Cmd.batch



-- UPDATE


type Msg
    = Tick Posix
    | SetCurrentTime Posix Zone
    | PostComponentMsg String Component.Post.Msg
    | DismissPostsClicked
    | PostsDismissed (Result Session.Error ( Session, DismissPosts.Response ))
    | PushSubscribeClicked
    | PostsRefreshed (Result Session.Error ( Session, InboxInit.Response ))
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

        PostsRefreshed (Ok ( newSession, resp )) ->
            let
                newPostComps =
                    Connection.map buildPostComponent resp.postWithRepliesIds

                newRepo =
                    Repo.union resp.repo globals.repo

                ( addedComps, removedComps ) =
                    Connection.diff .id newPostComps model.postComps

                setupCmds =
                    setupPostComps addedComps

                teardownCmds =
                    teardownPostComps removedComps
            in
            ( ( { model | postComps = newPostComps }
              , Cmd.batch [ setupCmds, teardownCmds ]
              )
            , { globals | session = newSession, repo = newRepo }
            )

        PostsRefreshed (Err Session.Expired) ->
            redirectToLogin globals model

        PostsRefreshed (Err _) ->
            noCmd globals model

        NoOp ->
            noCmd globals model


noCmd : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
noCmd globals model =
    ( ( model, Cmd.none ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )


refreshPosts : Params -> Globals -> Cmd Msg
refreshPosts params globals =
    globals.session
        |> InboxInit.request params
        |> Task.attempt PostsRefreshed



-- EVENTS


consumeEvent : Event -> Globals -> Model -> ( Model, Cmd Msg )
consumeEvent event globals model =
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
            ( model, refreshPosts model.params globals )

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
    case resolveData repo model of
        Just data ->
            resolvedView repo maybeCurrentRoute hasPushSubscription model data

        Nothing ->
            text "Something went wrong."


resolvedView : Repo -> Maybe Route -> Bool -> Model -> Data -> Html Msg
resolvedView repo maybeCurrentRoute hasPushSubscription model data =
    spaceLayout
        data.viewer
        data.space
        data.bookmarks
        maybeCurrentRoute
        [ div [ class "mx-56" ]
            [ div [ class "mx-auto max-w-90 leading-normal" ]
                [ div [ class "sticky pin-t mb-3 pt-4 bg-white z-50" ]
                    [ div [ class "border-b" ]
                        [ div [ class "flex items-center" ]
                            [ h2 [ class "flex-no-shrink font-extrabold text-2xl" ] [ text "Inbox" ]
                            , controlsView model data
                            ]
                        , div [ class "flex items-baseline" ]
                            [ filterTab "New Activity" Route.Inbox.Undismissed (undismissedParams model.params) model.params
                            , filterTab "Dismissed" Route.Inbox.Dismissed (dismissedParams model.params) model.params
                            ]
                        ]
                    ]
                , postsView repo model data
                , sidebarView data.space data.featuredUsers hasPushSubscription
                ]
            ]
        ]


filterTab : String -> Route.Inbox.Filter -> Params -> Params -> Html Msg
filterTab label filter linkParams currentParams =
    let
        isCurrent =
            Route.Inbox.getFilter currentParams == filter
    in
    a
        [ Route.href (Route.Inbox linkParams)
        , classList
            [ ( "block text-sm mr-4 py-2 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            ]
        ]
        [ text label ]


controlsView : Model -> Data -> Html Msg
controlsView model data =
    div [ class "flex flex-grow justify-end" ]
        [ selectionControlsView model.postComps
        , paginationView model.params model.postComps
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


paginationView : Params -> Connection a -> Html Msg
paginationView params connection =
    Pagination.view connection
        (\beforeCursor -> Route.Inbox (Route.Inbox.setCursors (Just beforeCursor) Nothing params))
        (\afterCursor -> Route.Inbox (Route.Inbox.setCursors Nothing (Just afterCursor) params))


postsView : Repo -> Model -> Data -> Html Msg
postsView repo model data =
    if Connection.isEmptyAndExpanded model.postComps then
        div [ class "pt-8 pb-8 text-center text-lg" ]
            [ text "You're all caught up!" ]

    else
        div [] <|
            Connection.mapList (postView repo model data) model.postComps


postView : Repo -> Model -> Data -> Component.Post.Model -> Html Msg
postView repo model data component =
    div [ class "py-4" ]
        [ component
            |> Component.Post.checkableView repo data.space data.viewer model.now
            |> Html.map (PostComponentMsg component.id)
        ]


sidebarView : Space -> List SpaceUser -> Bool -> Html Msg
sidebarView space featuredUsers hasPushSubscription =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-2 text-base font-extrabold" ]
            [ a
                [ Route.href (Route.SpaceUsers <| Route.SpaceUsers.init (Space.slug space))
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
            [ Route.href (Route.InviteUsers (Space.slug space))
            , class "block text-sm text-blue no-underline"
            ]
            [ text "Invite people" ]
        , a
            [ Route.href (Route.SpaceSettings (Space.slug space))
            , class "block text-sm text-blue no-underline"
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


undismissedParams : Params -> Params
undismissedParams params =
    params
        |> Route.Inbox.setCursors Nothing Nothing
        |> Route.Inbox.setFilter Route.Inbox.Undismissed


dismissedParams : Params -> Params
dismissedParams params =
    params
        |> Route.Inbox.setCursors Nothing Nothing
        |> Route.Inbox.setFilter Route.Inbox.Dismissed


unreadParams : Params -> Params
unreadParams params =
    params
        |> Route.Inbox.setCursors Nothing Nothing
        |> Route.Inbox.setFilter Route.Inbox.Unread


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
