module Page.NewInvitation exposing (ExternalMsg(..), Model, Msg, buildModel, initialCmd, update, view)

import Dom exposing (focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Task
import Data.Invitation as Invitation exposing (InvitationConnection)
import Data.Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorsFor)
import Mutation.CreateInvitation as CreateInvitation
import Mutation.RevokeInvitation as RevokeInvitation
import Query.Invitations
import Util exposing (Lazy(..), onEnter)


-- MODEL


type alias Model =
    { email : String
    , isSubmitting : Bool
    , errors : List ValidationError
    , invitations : Lazy InvitationConnection
    }


{-| Builds the initial model for the page.
-}
buildModel : Model
buildModel =
    Model "" False [] NotLoaded


{-| Determines whether the form is able to be submitted.
-}
isSubmittable : Model -> Bool
isSubmittable model =
    not (model.email == "") && model.isSubmitting == False


{-| Returns the initial command to run after the page is loaded.
-}
initialCmd : Session -> Cmd Msg
initialCmd session =
    Cmd.batch
        [ focusOnEmailField
        , fetchInvitations session
        ]



-- UPDATE


type Msg
    = EmailChanged String
    | Submit
    | Submitted (Result Http.Error CreateInvitation.Response)
    | Focused
    | InvitationsFetched (Result Http.Error Query.Invitations.Response)
    | RevokeInvitation String
    | RevokeInvitationResponse (Result Http.Error RevokeInvitation.Response)


type ExternalMsg
    = InvitationCreated Invitation.Invitation
    | NoOp


update : Msg -> Session -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg session model =
    case msg of
        EmailChanged val ->
            noCmd { model | email = val }

        Submit ->
            let
                request =
                    CreateInvitation.request session <|
                        CreateInvitation.Params model.email
            in
                if isSubmittable model then
                    ( ( { model | isSubmitting = True }
                      , Http.send Submitted request
                      )
                    , NoOp
                    )
                else
                    noCmd model

        Submitted (Ok (CreateInvitation.Success invitation)) ->
            let
                newModel =
                    newInvitationCreated model invitation
            in
                ( ( { newModel | errors = [], isSubmitting = False, email = "" }
                  , focusOnEmailField
                  )
                , InvitationCreated invitation
                )

        Submitted (Ok (CreateInvitation.Invalid errors)) ->
            ( ( { model | errors = errors, isSubmitting = False }, Cmd.none ), NoOp )

        Submitted (Err _) ->
            -- TODO: something unexpected went wrong - figure out best way to handle?
            ( ( { model | isSubmitting = False }, Cmd.none ), NoOp )

        Focused ->
            noCmd model

        InvitationsFetched (Ok (Query.Invitations.Found data)) ->
            ( ( { model | invitations = Loaded data.invitations }, Cmd.none ), NoOp )

        InvitationsFetched (Err _) ->
            -- TODO: something unexpected went wrong - figure out best way to handle?
            noCmd model

        RevokeInvitation id ->
            let
                request =
                    RevokeInvitation.request session <|
                        RevokeInvitation.Params id
            in
                ( ( model, Http.send RevokeInvitationResponse request ), NoOp )

        RevokeInvitationResponse (Ok (RevokeInvitation.Success id)) ->
            let
                newModel =
                    invitationRevoked model id
            in
                ( ( newModel, Cmd.none ), NoOp )

        RevokeInvitationResponse (Ok (RevokeInvitation.Invalid errors)) ->
            -- TODO: Show errors?
            noCmd model

        RevokeInvitationResponse (Err _) ->
            -- TODO: something unexpected went wrong - figure out best way to handle?
            noCmd model


noCmd : Model -> ( ( Model, Cmd Msg ), ExternalMsg )
noCmd model =
    ( ( model, Cmd.none ), NoOp )


focusOnEmailField : Cmd Msg
focusOnEmailField =
    Task.attempt (always Focused) <| focus "email-field"


fetchInvitations : Session -> Cmd Msg
fetchInvitations session =
    let
        params =
            Query.Invitations.Params "" 10
    in
        Http.send InvitationsFetched (Query.Invitations.request session params)


newInvitationCreated : Model -> Invitation.Invitation -> Model
newInvitationCreated model invitation =
    case model.invitations of
        NotLoaded ->
            model

        Loaded connection ->
            let
                newEdges =
                    { node = invitation } :: connection.edges

                newConnection =
                    { connection
                        | edges = newEdges
                        , totalCount = connection.totalCount + 1
                    }
            in
                { model | invitations = Loaded newConnection }


invitationRevoked : Model -> String -> Model
invitationRevoked model id =
    case model.invitations of
        NotLoaded ->
            model

        Loaded connection ->
            let
                newEdges =
                    List.filter (\edge -> not <| edge.node.id == id) connection.edges

                newConnection =
                    { connection
                        | edges = newEdges
                        , totalCount = connection.totalCount - 1
                    }
            in
                { model | invitations = Loaded newConnection }



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "main", class "main main--scrollable" ]
        [ div [ class "cform" ]
            [ div [ class "cform__header" ]
                [ h2 [ class "cform__heading" ] [ text "Invite a person" ]
                , p [ class "cform__description" ]
                    [ text "They will be given member-level permissions to start (you can grant them greater access later if needed)." ]
                ]
            , div [ class "cform__form" ]
                [ inputField "email" "email" "Email Address" model.email EmailChanged model
                , div [ class "form-controls" ]
                    [ input
                        [ type_ "submit"
                        , value "Send now"
                        , class "button button--primary button--large"
                        , disabled (not <| isSubmittable model)
                        , onClick Submit
                        ]
                        []
                    ]
                ]
            , invitationsList model
            ]
        ]


inputField : String -> String -> String -> String -> (String -> Msg) -> Model -> Html Msg
inputField fieldType fieldName labelText fieldValue inputMsg model =
    let
        errors =
            errorsFor fieldName model.errors
    in
        div
            [ classList
                [ ( "form-field", True )
                , ( "form-field--error", not (List.isEmpty errors) )
                ]
            ]
            [ label [ class "form-label" ] [ text labelText ]
            , input
                [ type_ fieldType
                , id (fieldName ++ "-field")
                , class "text-field text-field--full text-field--large"
                , name fieldName
                , value fieldValue
                , onInput inputMsg
                , onEnter Submit
                , disabled model.isSubmitting
                ]
                []
            , formErrors errors
            ]


formErrors : List ValidationError -> Html Msg
formErrors errors =
    case errors of
        error :: _ ->
            div [ class "form-errors" ] [ text error.message ]

        [] ->
            text ""


invitationsList : Model -> Html Msg
invitationsList model =
    case model.invitations of
        NotLoaded ->
            text ""

        Loaded data ->
            if data.totalCount <= 0 then
                text ""
            else
                let
                    displayCount =
                        toString data.totalCount

                    listItem edge =
                        div [ class "resource-list__item" ]
                            [ div [ class "resource-list__content" ]
                                [ h3 [ class "resource-list__heading" ] [ text edge.node.email ] ]
                            , div [ class "resource-list__controls" ]
                                [ button
                                    [ class "button button--tiny button--subdued"
                                    , onClick <| RevokeInvitation edge.node.id
                                    ]
                                    [ text "Revoke" ]
                                ]
                            ]
                in
                    div [ class "cform__section" ]
                        [ h2 [ class "cform__section-heading" ] [ text <| "Pending Invitations (" ++ displayCount ++ ")" ]
                        , div [ class "resource-list" ] (List.map listItem data.edges)
                        ]
