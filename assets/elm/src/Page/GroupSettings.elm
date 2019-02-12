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
import Mutation.GrantPrivateGroupAccess as GrantPrivateGroupAccess
import Mutation.PrivatizeGroup as PrivatizeGroup
import Mutation.PublicizeGroup as PublicizeGroup
import Mutation.ReopenGroup as ReopenGroup
import Mutation.RevokePrivateGroupAccess as RevokePrivateGroupAccess
import Mutation.UpdateGroup as UpdateGroup
import Pagination
import Query.GroupSettingsInit as GroupSettingsInit
import Repo exposing (Repo)
import Route exposing (Route)
import Route.Group
import Route.GroupSettings exposing (Params)
import Scroll
import Session exposing (Session)
import Set
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
    , isDefault : Bool
    , isPrivate : Bool
    , spaceUserIds : List Id
    , ownerIds : List Id
    , privateAccessorIds : List Id
    , isSubmitting : Bool

    -- MOBILE
    , showNav : Bool
    , showSidebar : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , group : Group
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
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
                resp.isDefault
                resp.isPrivate
                resp.spaceUserIds
                resp.ownerIds
                resp.privateAccessorIds
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
    | ToggleKeyboardCommands
    | UserToggled Id
    | PrivateGroupAccessRevoked Id (Result Session.Error ( Session, RevokePrivateGroupAccess.Response ))
    | PrivateGroupAccessGranted Id (Result Session.Error ( Session, GrantPrivateGroupAccess.Response ))
    | CloseClicked
    | Closed (Result Session.Error ( Session, CloseGroup.Response ))
    | ReopenClicked
    | Reopened (Result Session.Error ( Session, ReopenGroup.Response ))
    | DefaultToggled
    | GroupUpdated (Result Session.Error ( Session, UpdateGroup.Response ))
    | MakePublicChecked
    | MakePrivateChecked
    | GroupPrivatized (Result Session.Error ( Session, PrivatizeGroup.Response ))
    | GroupPublicized (Result Session.Error ( Session, PublicizeGroup.Response ))
      -- MOBILE
    | NavToggled
    | SidebarToggled
    | ScrollTopClicked


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        UserToggled toggledId ->
            let
                ( newPrivateSpaceUserIds, cmd ) =
                    if List.member toggledId model.privateAccessorIds then
                        ( ListHelpers.removeBy identity toggledId model.privateAccessorIds
                        , globals.session
                            |> RevokePrivateGroupAccess.request (RevokePrivateGroupAccess.variables model.spaceId model.groupId toggledId)
                            |> Task.attempt (PrivateGroupAccessRevoked toggledId)
                        )

                    else
                        ( ListHelpers.insertUniqueBy identity toggledId model.privateAccessorIds
                        , globals.session
                            |> GrantPrivateGroupAccess.request (GrantPrivateGroupAccess.variables model.spaceId model.groupId toggledId)
                            |> Task.attempt (PrivateGroupAccessGranted toggledId)
                        )
            in
            ( ( { model | privateAccessorIds = newPrivateSpaceUserIds }, cmd ), globals )

        PrivateGroupAccessRevoked spaceUserId (Ok ( newSession, _ )) ->
            let
                newPrivateSpaceUserIds =
                    ListHelpers.removeBy identity spaceUserId model.privateAccessorIds
            in
            ( ( { model | privateAccessorIds = newPrivateSpaceUserIds }, Cmd.none ), { globals | session = newSession } )

        PrivateGroupAccessRevoked _ (Err Session.Expired) ->
            redirectToLogin globals model

        PrivateGroupAccessRevoked _ (Err _) ->
            ( ( model, Cmd.none ), globals )

        PrivateGroupAccessGranted spaceUserId (Ok ( newSession, _ )) ->
            let
                newPrivateSpaceUserIds =
                    ListHelpers.insertUniqueBy identity spaceUserId model.privateAccessorIds
            in
            ( ( { model | privateAccessorIds = newPrivateSpaceUserIds }, Cmd.none ), { globals | session = newSession } )

        PrivateGroupAccessGranted _ (Err Session.Expired) ->
            redirectToLogin globals model

        PrivateGroupAccessGranted _ (Err _) ->
            ( ( model, Cmd.none ), globals )

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

        MakePublicChecked ->
            let
                cmd =
                    globals.session
                        |> PublicizeGroup.request (PublicizeGroup.variables model.spaceId model.groupId)
                        |> Task.attempt GroupPublicized
            in
            ( ( { model | isPrivate = False, isSubmitting = True }, cmd ), globals )

        MakePrivateChecked ->
            let
                cmd =
                    globals.session
                        |> PrivatizeGroup.request (PrivatizeGroup.variables model.spaceId model.groupId)
                        |> Task.attempt GroupPrivatized
            in
            ( ( { model | isPrivate = True, isSubmitting = True }, cmd ), globals )

        GroupPrivatized (Ok ( newSession, PrivatizeGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( { model | isSubmitting = False }, Cmd.none )
            , { globals
                | session = newSession
                , repo = newRepo
                , flash = Flash.set Flash.Notice "Channel made private" 3000 globals.flash
              }
            )

        GroupPrivatized (Ok ( newSession, _ )) ->
            ( ( { model | isSubmitting = False }, Cmd.none )
            , { globals | session = newSession }
            )

        GroupPrivatized (Err Session.Expired) ->
            redirectToLogin globals model

        GroupPrivatized (Err _) ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals )

        GroupPublicized (Ok ( newSession, PublicizeGroup.Success group )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setGroup group
            in
            ( ( { model | isSubmitting = False }, Cmd.none )
            , { globals
                | session = newSession
                , repo = newRepo
                , flash = Flash.set Flash.Notice "Channel made public" 3000 globals.flash
              }
            )

        GroupPublicized (Ok ( newSession, _ )) ->
            ( ( { model | isSubmitting = False }, Cmd.none )
            , { globals | session = newSession }
            )

        GroupPublicized (Err Session.Expired) ->
            redirectToLogin globals model

        GroupPublicized (Err _) ->
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
                (Route.GroupSettings.getGroupName model.params)

        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , currentRoute = globals.currentRoute
            , flash = globals.flash
            , showKeyboardCommands = globals.showKeyboardCommands
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
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
                , filterTab Device.Desktop "Permissions" Route.GroupSettings.Permissions (Route.GroupSettings.setSection Route.GroupSettings.Permissions model.params) model.params
                ]
            , viewIf (Route.GroupSettings.getSection model.params == Route.GroupSettings.General) <|
                generalView model data
            , viewIf (Route.GroupSettings.getSection model.params == Route.GroupSettings.Permissions) <|
                permissionsView globals model data
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
                (Route.GroupSettings.getGroupName model.params)

        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
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
                , filterTab Device.Mobile "Permissions" Route.GroupSettings.Permissions (Route.GroupSettings.setSection Route.GroupSettings.Permissions model.params) model.params
                ]
            , div [ class "p-4" ]
                [ viewIf (Route.GroupSettings.getSection model.params == Route.GroupSettings.General) <|
                    generalView model data
                , viewIf (Route.GroupSettings.getSection model.params == Route.GroupSettings.Permissions) <|
                    permissionsView globals model data
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
            [ ( "block text-md py-3 px-4 border-b-3 border-transparent no-underline font-bold", True )
            , ( "text-dusty-blue", not isCurrent )
            , ( "border-turquoise text-turquoise-dark", isCurrent )
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
                , disabled model.isPrivate
                ]
                []
            , span [ class "control-indicator" ] []
            , span [ class "select-none" ]
                [ text "Auto-subscribe new members to this channel"
                , viewIf model.isPrivate <|
                    text " (disallowed because this channel is private)"
                ]
            ]
        ]


permissionsView : Globals -> Model -> Data -> Html Msg
permissionsView globals model data =
    div [ class "mb-4 pb-16 border-b" ]
        [ ownersView globals.repo model
        , viewIf (Group.canManagePermissions data.group) <|
            div []
                [ label [ class "control radio pb-2" ]
                    [ input
                        [ type_ "radio"
                        , class "radio"
                        , onClick MakePublicChecked
                        , checked (not model.isPrivate)
                        ]
                        []
                    , span [ class "control-indicator" ] []
                    , span [ class "select-none" ] [ text "Anyone can see this channel" ]
                    ]
                , label [ class "control radio pb-3" ]
                    [ input
                        [ type_ "radio"
                        , class "radio"
                        , onClick MakePrivateChecked
                        , checked model.isPrivate
                        ]
                        []
                    , span [ class "control-indicator" ] []
                    , span [ class "select-none" ] [ text "Only people granted access can see this channel" ]
                    ]
                , viewIf model.isPrivate <|
                    privateAccessorsView globals.repo model
                ]
        ]


ownersView : Repo -> Model -> Html Msg
ownersView repo model =
    div [ class "mb-6" ]
        [ p [ class "mb-3" ] [ text "This channel is owned by:" ]
        , div []
            (model.ownerIds
                |> List.filterMap (\id -> Repo.getSpaceUser id repo)
                |> List.map (ownerView model)
            )
        ]


ownerView : Model -> SpaceUser -> Html Msg
ownerView model spaceUser =
    div [ class "flex items-center pr-4 pb-1 font-normal text-base select-none" ]
        [ div [ class "mr-3" ] [ SpaceUser.avatar Avatar.Small spaceUser ]
        , text (SpaceUser.displayName spaceUser)
        ]


privateAccessorsView : Repo -> Model -> Html Msg
privateAccessorsView repo model =
    let
        nonOwnerIds =
            model.ownerIds
                |> Set.fromList
                |> Set.diff (Set.fromList model.spaceUserIds)
                |> Set.toList
    in
    div [ style "margin-left" "38px" ]
        (nonOwnerIds
            |> List.filterMap (\id -> Repo.getSpaceUser id repo)
            |> List.map (privateAccessorView model)
        )


privateAccessorView : Model -> SpaceUser -> Html Msg
privateAccessorView model spaceUser =
    div []
        [ label [ class "control checkbox flex items-center pr-4 pb-1 font-normal text-md select-none" ]
            [ div [ class "flex-0" ]
                [ input
                    [ type_ "checkbox"
                    , class "checkbox"
                    , onClick (UserToggled (SpaceUser.id spaceUser))
                    , checked (List.member (SpaceUser.id spaceUser) model.privateAccessorIds)
                    , disabled model.isSubmitting
                    ]
                    []
                , span [ class "control-indicator w-4 h-4 mr-2 border" ] []
                ]
            , div [ class "mr-2" ] [ SpaceUser.avatar Avatar.Tiny spaceUser ]
            , text (SpaceUser.displayName spaceUser)
            ]
        ]



-- INTERNAL


isNotSubmittable : Model -> Bool
isNotSubmittable model =
    model.isSubmitting
