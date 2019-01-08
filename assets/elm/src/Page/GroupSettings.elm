module Page.GroupSettings exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Avatar
import Connection exposing (Connection)
import Device exposing (Device)
import Event exposing (Event)
import Flash
import Globals exposing (Globals)
import Group exposing (Group)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Id exposing (Id)
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.CloseGroup as CloseGroup
import Mutation.ReopenGroup as ReopenGroup
import Mutation.UpdateGroup as UpdateGroup
import Pagination
import Query.GroupSettingsInit as GroupSettingsInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.GroupSettings exposing (Params)
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import Tuple
import View.Helpers exposing (viewIf)



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , groupId : Id
    , bookmarkIds : List Id
    , isDefault : Bool
    , spaceUserIds : List Id
    , selectedIds : List Id
    , isSubmitting : Bool

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , bookmarks : List Group
    , group : Group
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map4 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Just <| Repo.getGroups model.bookmarkIds repo)
        (Repo.getGroup model.groupId repo)



-- PAGE ATTRIBUTES


title : String
title =
    "Channel Settings"



-- LIFECYCLE


init : Params -> Globals -> Task Session.Error ( Globals, Model )
init params globals =
    globals.session
        |> GroupSettingsInit.request params
        |> Task.map (buildModel params globals)


buildModel : Params -> Globals -> ( Session, GroupSettingsInit.Response ) -> ( Globals, Model )
buildModel params globals ( newSession, resp ) =
    let
        model =
            Model
                params
                resp.viewerId
                resp.spaceId
                resp.groupId
                resp.bookmarkIds
                resp.isDefault
                resp.spaceUserIds
                []
                False
                False
                False

        newRepo =
            Repo.union resp.repo globals.repo
    in
    ( { globals | session = newSession, repo = newRepo }, model )


setup : Model -> Cmd Msg
setup model =
    Scroll.toDocumentTop NoOp


teardown : Model -> Cmd Msg
teardown model =
    Cmd.none



-- UPDATE


type Msg
    = NoOp
    | UserToggled Id
    | CloseClicked
    | Closed (Result Session.Error ( Session, CloseGroup.Response ))
    | ReopenClicked
    | Reopened (Result Session.Error ( Session, ReopenGroup.Response ))
    | DefaultToggled
    | GroupUpdated (Result Session.Error ( Session, UpdateGroup.Response ))
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        UserToggled toggledId ->
            let
                newSelectedIds =
                    if List.member toggledId model.selectedIds then
                        ListHelpers.removeBy identity toggledId model.selectedIds

                    else
                        ListHelpers.insertUniqueBy identity toggledId model.selectedIds
            in
            ( ( { model | selectedIds = newSelectedIds }, Cmd.none ), globals )

        CloseClicked ->
            let
                cmd =
                    globals.session
                        |> CloseGroup.request model.spaceId model.groupId
                        |> Task.attempt Closed
            in
            ( ( model, cmd ), globals )

        Closed (Ok ( newSession, CloseGroup.Success newGroup )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup newGroup
            in
            ( ( model, Cmd.none ), { globals | session = newSession, repo = newRepo } )

        Closed (Err Session.Expired) ->
            redirectToLogin globals model

        Closed (Err _) ->
            ( ( model, Cmd.none ), globals )

        ReopenClicked ->
            let
                cmd =
                    globals.session
                        |> ReopenGroup.request model.spaceId model.groupId
                        |> Task.attempt Reopened
            in
            ( ( model, cmd ), globals )

        Reopened (Ok ( newSession, ReopenGroup.Success newGroup )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup newGroup
            in
            ( ( model, Cmd.none ), { globals | session = newSession, repo = newRepo } )

        Reopened (Err Session.Expired) ->
            redirectToLogin globals model

        Reopened (Err _) ->
            ( ( model, Cmd.none ), globals )

        DefaultToggled ->
            let
                variables =
                    UpdateGroup.isDefaultVariables model.spaceId model.groupId (not model.isDefault)

                cmd =
                    globals.session
                        |> UpdateGroup.request variables
                        |> Task.attempt GroupUpdated
            in
            ( ( { model | isDefault = not model.isDefault, isSubmitting = True }, cmd ), globals )

        GroupUpdated (Ok ( newSession, UpdateGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( { model | isSubmitting = False }, Cmd.none )
            , { globals
                | session = newSession
                , repo = newRepo
                , flash = Flash.set Flash.Notice "Settings updated" 3000 globals.flash
              }
            )

        GroupUpdated (Ok ( newSession, _ )) ->
            ( ( { model | isSubmitting = False }, Cmd.none )
            , { globals | session = newSession }
            )

        GroupUpdated (Err Session.Expired) ->
            redirectToLogin globals model

        GroupUpdated (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals )

        NavToggled ->
            ( ( { model | showNav = not model.showNav }, Cmd.none ), globals )

        SidebarToggled ->
            ( ( { model | showSidebar = not model.showSidebar }, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )


redirectToLogin : Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
redirectToLogin globals model =
    ( ( model, Route.toLogin ), globals )



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


view : Globals -> Model -> Html Msg
view globals model =
    case resolveData globals.repo model of
        Just data ->
            resolvedView globals model data

        Nothing ->
            text "Something went wrong."


resolvedView : Globals -> Model -> Data -> Html Msg
resolvedView globals model data =
    case globals.device of
        Device.Desktop ->
            resolvedDesktopView globals model data

        Device.Mobile ->
            resolvedMobileView globals model data



-- DESKTOP


resolvedDesktopView : Globals -> Model -> Data -> Html Msg
resolvedDesktopView globals model data =
    let
        groupParams =
            Route.Group.init
                (Route.GroupSettings.getSpaceSlug model.params)
                (Route.GroupSettings.getGroupId model.params)

        config =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , showKeyboardCommands = globals.showKeyboardCommands
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "mx-auto max-w-sm leading-normal p-8" ]
            [ div [ class "pb-4" ]
                [ nav [ class "text-xl font-headline font-bold leading-tight" ]
                    [ a
                        [ Route.href (Route.Group groupParams)
                        , class "no-underline text-dusty-blue-dark"
                        ]
                        [ text <| "#" ++ Group.name data.group ]
                    ]
                , h1 [ class "flex-1 font-bold tracking-semi-tight text-3xl" ] [ text "Channel Settings" ]
                ]
            , div [ class "flex items-baseline mb-6 border-b" ]
                [ filterTab Device.Desktop "General" Route.GroupSettings.General (Route.GroupSettings.setSection Route.GroupSettings.General model.params) model.params
                ]
            , viewIf (Route.GroupSettings.getSection model.params == Route.GroupSettings.General) <|
                generalView model data
            , viewIf (Group.state data.group == Group.Open) <|
                button
                    [ class "text-md text-dusty-blue no-underline font-bold"
                    , onClick CloseClicked
                    ]
                    [ text "Close this channel" ]
            , viewIf (Group.state data.group == Group.Closed) <|
                button
                    [ class "text-md text-dusty-blue no-underline font-bold"
                    , onClick ReopenClicked
                    ]
                    [ text "Reopen this channel" ]
            ]
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        groupParams =
            Route.Group.init
                (Route.GroupSettings.getSpaceSlug model.params)
                (Route.GroupSettings.getGroupId model.params)

        config =
            { space = data.space
            , spaceUser = data.viewer
            , bookmarks = data.bookmarks
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , title = "Group Settings"
            , showNav = model.showNav
            , onNavToggled = NavToggled
            , onSidebarToggled = SidebarToggled
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.Back (Route.Group groupParams)
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "mx-auto leading-normal" ]
            [ div [ class "flex justify-center items-baseline mb-3 px-3 pt-2 border-b" ]
                [ filterTab Device.Mobile "General" Route.GroupSettings.General (Route.GroupSettings.setSection Route.GroupSettings.General model.params) model.params
                ]
            , div [ class "p-4" ]
                [ viewIf (Route.GroupSettings.getSection model.params == Route.GroupSettings.General) <|
                    generalView model data
                , viewIf (Group.state data.group == Group.Open) <|
                    button
                        [ class "text-md text-dusty-blue no-underline font-bold"
                        , onClick CloseClicked
                        ]
                        [ text "Close this channel" ]
                , viewIf (Group.state data.group == Group.Closed) <|
                    button
                        [ class "text-md text-dusty-blue no-underline font-bold"
                        , onClick ReopenClicked
                        ]
                        [ text "Reopen this channel" ]
                ]
            ]
        ]



-- SHARED


filterTab : Device -> String -> Route.GroupSettings.Section -> Params -> Params -> Html Msg
filterTab device label section linkParams currentParams =
    let
        isCurrent =
            Route.GroupSettings.getSection currentParams == section
    in
    a
        [ Route.href (Route.GroupSettings linkParams)
        , classList
            [ ( "block text-sm mr-4 py-2 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-dusty-blue-darker", isCurrent )
            , ( "text-center min-w-100px", device == Device.Mobile )
            ]
        ]
        [ text label ]


generalView : Model -> Data -> Html Msg
generalView model data =
    div [ class "mb-4 pb-16 border-b" ]
        [ label [ class "control checkbox pb-6" ]
            [ input
                [ type_ "checkbox"
                , class "checkbox"
                , onClick DefaultToggled
                , checked model.isDefault
                , disabled model.isSubmitting
                ]
                []
            , span [ class "control-indicator" ] []
            , span [ class "select-none" ] [ text "Add people to this channel by default" ]
            ]
        ]


permissionsView : Repo -> Model -> Html Msg
permissionsView repo model =
    div []
        [ div [ class "pb-6" ]
            [ p [ class "text-base" ]
                [ text "Manage who is allowed in the channel and appoint other owners to help admininstrate it."
                ]
            ]
        , usersView repo model
        ]


usersView : Repo -> Model -> Html Msg
usersView repo model =
    div [ class "pb-6" ]
        (model.spaceUserIds
            |> List.filterMap (\id -> Repo.getSpaceUser id repo)
            |> List.map (userView model)
        )


userView : Model -> SpaceUser -> Html Msg
userView model spaceUser =
    div []
        [ label [ class "control checkbox flex items-center pr-4 pb-1 font-normal text-base select-none" ]
            [ div [ class "flex-0" ]
                [ input
                    [ type_ "checkbox"
                    , class "checkbox"
                    , onClick (UserToggled (SpaceUser.id spaceUser))
                    , checked (List.member (SpaceUser.id spaceUser) model.selectedIds)
                    , disabled model.isSubmitting
                    ]
                    []
                , span [ class "control-indicator" ] []
                ]
            , div [ class "mr-3" ] [ SpaceUser.avatar Avatar.Small spaceUser ]
            , text (SpaceUser.displayName spaceUser)
            ]
        ]



-- INTERNAL


isNotSubmittable : Model -> Bool
isNotSubmittable model =
    List.isEmpty model.selectedIds || model.isSubmitting
