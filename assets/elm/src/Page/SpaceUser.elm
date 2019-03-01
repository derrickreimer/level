module Page.SpaceUser exposing (Model, Msg(..), consumeEvent, init, setup, teardown, title, update, view)

import Avatar
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
import Json.Decode as Decode
import Layout.SpaceDesktop
import Layout.SpaceMobile
import ListHelpers exposing (insertUniqueBy, removeBy)
import Mutation.RevokeSpaceAccess as RevokeSpaceAccess
import Mutation.UpdateRole as UpdateRole
import PageError exposing (PageError)
import Repo exposing (Repo)
import Route exposing (Route)
import Route.SpaceUser exposing (Params)
import Route.SpaceUsers
import Scroll
import Session exposing (Session)
import Space exposing (Space)
import SpaceUser exposing (SpaceUser)
import Task exposing (Task)
import View.Helpers exposing (viewIf)



-- MODEL


type alias Model =
    { params : Params
    , viewerId : Id
    , spaceId : Id
    , spaceUserId : Id
    , role : SpaceUser.Role
    , showPermissionsModal : Bool
    , isSubmitting : Bool
    }


type alias Data =
    { viewer : SpaceUser
    , space : Space
    , spaceUser : SpaceUser
    }


resolveData : Repo -> Model -> Maybe Data
resolveData repo model =
    Maybe.map3 Data
        (Repo.getSpaceUser model.viewerId repo)
        (Repo.getSpace model.spaceId repo)
        (Repo.getSpaceUser model.spaceUserId repo)



-- PAGE ATTRIBUTES


title : String
title =
    "View user"



-- LIFECYCLE


init : Params -> Globals -> Task PageError ( Globals, Model )
init params globals =
    let
        maybeUserId =
            Session.getUserId globals.session

        maybeSpaceId =
            globals.repo
                |> Repo.getSpaceBySlug (Route.SpaceUser.getSpaceSlug params)
                |> Maybe.andThen (Just << Space.id)

        maybeViewerId =
            case ( maybeSpaceId, maybeUserId ) of
                ( Just spaceId, Just userId ) ->
                    Repo.getSpaceUserByUserId spaceId userId globals.repo
                        |> Maybe.andThen (Just << SpaceUser.id)

                _ ->
                    Nothing

        maybeSpaceUser =
            case maybeSpaceId of
                Just spaceId ->
                    globals.repo
                        |> Repo.getSpaceUserByHandle spaceId (Route.SpaceUser.getHandle params)

                Nothing ->
                    Nothing
    in
    case ( maybeViewerId, maybeSpaceId, maybeSpaceUser ) of
        ( Just viewerId, Just spaceId, Just spaceUser ) ->
            let
                model =
                    Model
                        params
                        viewerId
                        spaceId
                        (SpaceUser.id spaceUser)
                        (SpaceUser.role spaceUser)
                        False
                        False
            in
            Task.succeed ( globals, model )

        _ ->
            Task.fail PageError.NotFound


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
    | ToggleNotifications
    | TogglePermissionsModal
    | RevokeAccess
    | AccessRevoked (Result Session.Error ( Session, RevokeSpaceAccess.Response ))
    | ScrollTopClicked
    | SetMemberRole
    | SetAdminRole
    | SetOwnerRole
    | RoleUpdated (Result Session.Error ( Session, UpdateRole.Response ))


update : Msg -> Globals -> Model -> ( ( Model, Cmd Msg ), Globals )
update msg globals model =
    case msg of
        NoOp ->
            ( ( model, Cmd.none ), globals )

        ToggleKeyboardCommands ->
            ( ( model, Cmd.none ), { globals | showKeyboardCommands = not globals.showKeyboardCommands } )

        ToggleNotifications ->
            ( ( model, Cmd.none ), { globals | showNotifications = not globals.showNotifications } )

        TogglePermissionsModal ->
            case resolveData globals.repo model of
                Just data ->
                    ( ( { model
                            | showPermissionsModal = not model.showPermissionsModal
                            , role = SpaceUser.role data.spaceUser
                        }
                      , Cmd.none
                      )
                    , globals
                    )

                Nothing ->
                    ( ( { model
                            | showPermissionsModal = not model.showPermissionsModal
                        }
                      , Cmd.none
                      )
                    , globals
                    )

        RevokeAccess ->
            let
                cmd =
                    globals.session
                        |> RevokeSpaceAccess.request (RevokeSpaceAccess.variables model.spaceId model.spaceUserId)
                        |> Task.attempt AccessRevoked
            in
            ( ( model, cmd ), globals )

        AccessRevoked (Ok ( newSession, resp )) ->
            let
                newGlobals =
                    { globals
                        | session = newSession
                        , flash = Flash.set Flash.Notice "User removed" 3000 globals.flash
                    }

                listParams =
                    Route.SpaceUsers.init (Route.SpaceUser.getSpaceSlug model.params)

                cmd =
                    Route.pushUrl globals.navKey (Route.SpaceUsers listParams)
            in
            ( ( model, cmd ), newGlobals )

        AccessRevoked (Err Session.Expired) ->
            ( ( model, Route.toLogin ), globals )

        AccessRevoked (Err _) ->
            ( ( model, Cmd.none ), globals )

        ScrollTopClicked ->
            ( ( model, Scroll.toDocumentTop NoOp ), globals )

        SetMemberRole ->
            let
                variables =
                    UpdateRole.variables model.spaceId model.spaceUserId SpaceUser.Member

                cmd =
                    globals.session
                        |> UpdateRole.request variables
                        |> Task.attempt RoleUpdated
            in
            ( ( { model | role = SpaceUser.Member, isSubmitting = True }, cmd ), globals )

        SetAdminRole ->
            let
                variables =
                    UpdateRole.variables model.spaceId model.spaceUserId SpaceUser.Admin

                cmd =
                    globals.session
                        |> UpdateRole.request variables
                        |> Task.attempt RoleUpdated
            in
            ( ( { model | role = SpaceUser.Admin, isSubmitting = True }, cmd ), globals )

        SetOwnerRole ->
            let
                variables =
                    UpdateRole.variables model.spaceId model.spaceUserId SpaceUser.Owner

                cmd =
                    globals.session
                        |> UpdateRole.request variables
                        |> Task.attempt RoleUpdated
            in
            ( ( { model | role = SpaceUser.Owner, isSubmitting = True }, cmd ), globals )

        RoleUpdated (Ok ( newSession, UpdateRole.Success newSpaceUser )) ->
            let
                newRepo =
                    globals.repo
                        |> Repo.setSpaceUser newSpaceUser

                newGlobals =
                    { globals | session = newSession, repo = newRepo }
            in
            ( ( { model | isSubmitting = False }, Cmd.none ), newGlobals )

        RoleUpdated (Err Session.Expired) ->
            ( ( { model | isSubmitting = False }, Route.toLogin ), globals )

        RoleUpdated _ ->
            ( ( { model | isSubmitting = False }, Cmd.none ), globals )



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
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , onNoOp = NoOp
            , onToggleKeyboardCommands = ToggleKeyboardCommands
            , onPageClicked = NoOp
            , onToggleNotifications = ToggleNotifications
            }
    in
    Layout.SpaceDesktop.layout config
        [ div [ class "max-w-md mx-auto" ]
            [ div [ class "px-8" ]
                [ div [ class "pb-4 pt-6 border-b" ]
                    [ a
                        [ Route.href <| Route.SpaceUsers (Route.SpaceUsers.init (Route.SpaceUser.getSpaceSlug model.params))
                        , class "flex items-center font-bold text-dusty-blue no-underline"
                        ]
                        [ text "View the member list"
                        ]
                    ]
                ]
            , div [ class "px-8 py-6" ] [ detailView model data ]
            ]
        , viewIf model.showPermissionsModal <|
            permissionsModal model data
        ]



-- MOBILE


resolvedMobileView : Globals -> Model -> Data -> Html Msg
resolvedMobileView globals model data =
    let
        config =
            { globals = globals
            , space = data.space
            , spaceUser = data.viewer
            , title = "People"
            , showNav = False
            , onNavToggled = NoOp
            , onSidebarToggled = NoOp
            , onScrollTopClicked = ScrollTopClicked
            , onNoOp = NoOp
            , leftControl = Layout.SpaceMobile.Back (Route.SpaceUsers (Route.SpaceUsers.init (Route.SpaceUser.getSpaceSlug model.params)))
            , rightControl = Layout.SpaceMobile.NoControl
            }
    in
    Layout.SpaceMobile.layout config
        [ div [ class "p-3 leading-tight" ]
            [ detailView model data
            ]
        , viewIf model.showPermissionsModal <|
            permissionsModal model data
        ]



-- SHARED


detailView : Model -> Data -> Html Msg
detailView model data =
    div [ class "flex mb-4 pb-6" ]
        [ div [ class "flex-no-shrink mr-4" ] [ SpaceUser.avatar Avatar.XLarge data.spaceUser ]
        , div [ class "flex-grow" ]
            [ div [ class "flex items-center" ]
                [ h1 [ class "mb-1 font-bold text-3xl tracking-semi-tight" ] [ text (SpaceUser.displayName data.spaceUser) ]
                , viewIf (SpaceUser.state data.spaceUser == SpaceUser.Disabled) <|
                    span [ class "ml-4 px-3 py-1 text-sm border rounded-full text-dusty-blue-dark select-none" ] [ text "Account disabled" ]
                ]
            , h2 [ class "font-normal text-dusty-blue-dark text-xl" ] [ text <| "@" ++ SpaceUser.handle data.spaceUser ]
            ]
        , div [ class "flex-no-shrink ml-4" ]
            [ viewIf (canManageAccess model data) <|
                button
                    [ class "flex tooltip tooltip-bottom items-center text-dusty-blue no-underline font-bold no-outline"
                    , onClick TogglePermissionsModal
                    , attribute "data-tooltip" "Permissions"
                    ]
                    [ div [] [ Icons.shield ]
                    ]
            ]
        ]


canRevoke : Model -> Data -> Bool
canRevoke model data =
    SpaceUser.canManageMembers data.viewer
        && (not (model.role == SpaceUser.Owner) || SpaceUser.canManageOwners data.viewer)
        && model.viewerId
        /= model.spaceUserId


canManageAccess : Model -> Data -> Bool
canManageAccess model data =
    SpaceUser.canManageMembers data.viewer
        && SpaceUser.state data.spaceUser
        == SpaceUser.Active


permissionsModal : Model -> Data -> Html Msg
permissionsModal model data =
    div
        [ class "fixed pin-l pin-t pin-r pin-b z-50"
        , style "background-color" "rgba(0,0,0,0.5)"
        , onClick TogglePermissionsModal
        ]
        [ div [ class "mx-auto max-w-md md:max-w-lg px-8 py-24" ]
            [ div
                [ class "w-full bg-white rounded-lg shadow-lg leading-normal"
                , stopPropagationOn "click" (Decode.map alwaysStopPropagation (Decode.succeed NoOp))
                ]
                [ div [ class "flex px-8 md:px-12 py-6 rounded-t-lg bg-grey-lighter" ]
                    [ div [ class "flex-grow" ]
                        [ h2 [ class "mb-3 font-normal text-dusty-blue-darkest tracking-semi-tight text-3xl" ] [ text "Permissions" ]
                        , p [ class "text-dusty-blue-dark" ] [ text <| "Designate " ++ SpaceUser.firstName data.spaceUser ++ "'s role on the " ++ Space.name data.space ++ " team." ]
                        ]
                    , div [ class "flex-no-shrink" ]
                        [ button [ onClick TogglePermissionsModal ] [ Icons.ex ]
                        ]
                    ]
                , div [ class "px-8 md:px-12 py-2" ]
                    [ viewIf (SpaceUser.canManageOwners data.viewer || not (model.role == SpaceUser.Owner)) <|
                        label [ class "control radio items-start my-6" ]
                            [ input
                                [ type_ "radio"
                                , class "radio"
                                , name "role"
                                , checked (model.role == SpaceUser.Member)
                                , disabled (model.isSubmitting || not (SpaceUser.canManageMembers data.viewer))
                                , onClick SetMemberRole
                                ]
                                []
                            , span [ class "control-indicator" ] []
                            , div []
                                [ h3 [ class "mb-1 text-lg text-dusty-blue-darker font-sans" ] [ text "Regular Member" ]
                                , p [ class "text-dusty-blue-dark" ] [ text "The default role for team members." ]
                                ]
                            ]
                    , viewIf (SpaceUser.canManageOwners data.viewer || not (model.role == SpaceUser.Owner)) <|
                        label [ class "control radio items-start my-6" ]
                            [ input
                                [ type_ "radio"
                                , class "radio"
                                , name "role"
                                , checked (model.role == SpaceUser.Admin)
                                , disabled (model.isSubmitting || not (SpaceUser.canManageMembers data.viewer))
                                , onClick SetAdminRole
                                ]
                                []
                            , span [ class "control-indicator" ] []
                            , div []
                                [ h3 [ class "mb-1 text-lg text-dusty-blue-darker font-sans" ] [ text "Administrator" ]
                                , p [ class "text-dusty-blue-dark" ] [ text "Allow them to configure team settings and manage member permissions." ]
                                ]
                            ]
                    , label [ class "control radio items-start my-6" ]
                        [ input
                            [ type_ "radio"
                            , class "radio"
                            , name "role"
                            , checked (model.role == SpaceUser.Owner)
                            , disabled (model.isSubmitting || not (SpaceUser.canManageOwners data.viewer))
                            , onClick SetOwnerRole
                            ]
                            []
                        , span [ class "control-indicator" ] []
                        , div []
                            [ h3 [ class "mb-1 text-lg text-dusty-blue-darker font-sans" ] [ text "Team Owner" ]
                            , p [ class "text-dusty-blue-dark" ] [ text "Allow them to manage everything and designate other owners." ]
                            ]
                        ]
                    ]
                , viewIf (canRevoke model data) <|
                    div [ class "px-8 md:px-12 py-6 border-t rounded-b" ]
                        [ h3 [ class "mb-1 text-red text-lg font-sans" ] [ text "Remove from the team" ]
                        , p [ class "mb-3 text-dusty-blue-dark" ] [ text "Their posts will remain visible, but they will no longer have access." ]
                        , button [ class "mr-2 btn btn-red btn-sm", onClick RevokeAccess ] [ text "Revoke access" ]
                        ]
                ]
            ]
        ]


alwaysStopPropagation : msg -> ( msg, Bool )
alwaysStopPropagation msg =
    ( msg, True )
