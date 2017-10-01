module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick, onBlur)
import Http
import Query.Bootstrap as Bootstrap
import Mutation.CreateDraft as CreateDraft


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { apiToken : String
    , currentSpace : Maybe Space
    , currentUser : Maybe User
    , draft : Draft
    }


type alias Draft =
    { subject : String
    , body : String
    , recipientIds : List String
    }


type alias Space =
    { name : String
    }


type alias User =
    { firstName : String
    , lastName : String
    }


type alias Flags =
    { apiToken : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            initialState flags
    in
        ( model, (bootstrap model) )


initialState : Flags -> Model
initialState flags =
    { apiToken = flags.apiToken
    , currentUser = Nothing
    , currentSpace = Nothing
    , draft = Draft "" "" []
    }


displayName : User -> String
displayName user =
    user.firstName ++ " " ++ user.lastName


isDraftInvalid : Draft -> Bool
isDraftInvalid draft =
    (String.length draft.subject == 0) || (String.length draft.body == 0)



-- UPDATE


type Msg
    = Bootstrapped (Result Http.Error Bootstrap.Response)
    | DraftSubjectChanged String
    | DraftBodyChanged String
    | DraftSaveClicked
    | DraftSubmitted (Result Http.Error Bool)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Bootstrapped (Ok response) ->
            let
                currentUser =
                    User response.firstName response.lastName

                currentSpace =
                    Space response.space.name
            in
                ( { model | currentUser = Just currentUser, currentSpace = Just currentSpace }, Cmd.none )

        Bootstrapped (Err _) ->
            ( model, Cmd.none )

        DraftSubjectChanged subject ->
            let
                draft =
                    model.draft

                updatedDraft =
                    { draft | subject = subject }
            in
                ( { model | draft = updatedDraft }, Cmd.none )

        DraftBodyChanged body ->
            let
                draft =
                    model.draft

                updatedDraft =
                    { draft | body = body }
            in
                ( { model | draft = updatedDraft }, Cmd.none )

        DraftSaveClicked ->
            ( model, saveDraft model )

        DraftSubmitted (Ok response) ->
            ( model, Cmd.none )

        DraftSubmitted (Err _) ->
            ( model, Cmd.none )


bootstrap : Model -> Cmd Msg
bootstrap model =
    Http.send Bootstrapped (Bootstrap.request model.apiToken)


saveDraft : Model -> Cmd Msg
saveDraft model =
    Http.send DraftSubmitted (CreateDraft.request model.apiToken model.draft)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ div [ class "sidebar sidebar--left" ]
            [ spaceSelector model.currentSpace
            , filters model
            ]
        , div [ class "sidebar sidebar--right" ]
            [ identityMenu model.currentUser
            , usersList model
            ]
        , div [ class "main" ]
            [ div [ class "search-bar" ]
                [ input [ type_ "text", class "text-field text-field--muted search-field", placeholder "Search" ] [] ]
            , div [ class "threads" ]
                [ div [ class "threads__item threads__item--highlighted" ]
                    [ div [ class "threads__selector" ]
                        [ label [ class "checkbox" ]
                            [ input [ type_ "checkbox" ] []
                            , span [ class "checkbox__indicator" ] []
                            ]
                        ]
                    , div [ class "threads__metadata" ]
                        [ div [ class "threads__item-head" ]
                            [ span [ class "threads__subject" ] [ text "DynamoDB Brainstorming" ]
                            , span [ class "threads__dash" ] [ text "—" ]
                            , span [ class "threads__recipients" ] [ text "Developers" ]
                            ]
                        , div [ class "threads__preview" ] [ text "derrick: Have we evaluated all our options here?" ]
                        ]
                    , div [ class "threads__aside" ]
                        [ span [] [ text "12:00pm" ] ]
                    ]
                , div [ class "threads__item" ]
                    [ div [ class "threads__selector" ]
                        [ label [ class "checkbox" ]
                            [ input [ type_ "checkbox" ] []
                            , span [ class "checkbox__indicator" ] []
                            ]
                        ]
                    , div [ class "threads__metadata" ]
                        [ div [ class "threads__item-head" ]
                            [ span [ class "threads__subject" ] [ text "ID-pocalypse 2017" ]
                            , span [ class "threads__dash" ] [ text "—" ]
                            , span [ class "threads__recipients" ] [ text "Developers (+ 2 others)" ]
                            ]
                        , div [ class "threads__preview" ] [ text "derrick: Have we evaluated all our options here?" ]
                        ]
                    , div [ class "threads__aside" ]
                        [ span [ class "threads__unread" ] [ text "2 unread" ]
                        , span [ class "threads__timestamp" ] [ text "12:00pm" ]
                        ]
                    ]
                ]
            , div [ class "draft" ]
                [ div [ class "draft__row" ]
                    [ div [ class "draft__subject" ]
                        [ input
                            [ type_ "text"
                            , class "text-field text-field--muted draft__subject-field"
                            , placeholder "Subject"
                            , value model.draft.subject
                            , onInput DraftSubjectChanged
                            ]
                            []
                        ]
                    , div [ class "draft__recipients" ]
                        [ input [ type_ "text", class "text-field text-field--muted draft__recipients-field", placeholder "Recipients" ] []
                        ]
                    ]
                , div [ class "draft__row" ]
                    [ div [ class "draft__body" ]
                        [ textarea
                            [ class "text-field text-field--muted textarea draft__body-field"
                            , placeholder "Message"
                            , value model.draft.body
                            , onInput DraftBodyChanged
                            ]
                            []
                        ]
                    ]
                , div [ class "draft__row" ]
                    [ button [ class "button button--primary", disabled (isDraftInvalid model.draft) ] [ text "Start New Thread" ]
                    , button [ class "button button--secondary", onClick DraftSaveClicked ] [ text "Save Draft" ]
                    ]
                ]
            ]
        ]


spaceSelector : Maybe Space -> Html Msg
spaceSelector maybeSpace =
    case maybeSpace of
        Nothing ->
            div [ class "team-selector" ]
                [ a [ class "team-selector__toggle", href "#" ]
                    [ div [ class "team-selector__avatar team-selector__avatar--placeholder" ] []
                    , div [ class "team-selector__name team-selector__name" ]
                        [ div [ class "team-selector__loading-placeholder" ] []
                        ]
                    ]
                ]

        Just space ->
            div [ class "team-selector" ]
                [ a [ class "team-selector__toggle", href "#" ]
                    [ div [ class "team-selector__avatar" ] []
                    , div [ class "team-selector__name" ] [ text space.name ]
                    ]
                ]


identityMenu : Maybe User -> Html Msg
identityMenu maybeUser =
    case maybeUser of
        Nothing ->
            div [ class "identity-menu" ]
                [ a [ class "identity-menu__toggle", href "#" ]
                    [ div [ class "identity-menu__avatar identity-menu__avatar--placeholder" ] []
                    , div [ class "identity-menu__name" ]
                        [ div [ class "team-selector__loading-placeholder" ] []
                        ]
                    ]
                ]

        Just user ->
            div [ class "identity-menu" ]
                [ a [ class "identity-menu__toggle", href "#" ]
                    [ div [ class "identity-menu__avatar" ] []
                    , div [ class "identity-menu__name" ] [ text (displayName user) ]
                    ]
                ]


filters : Model -> Html Msg
filters model =
    div [ class "filters" ]
        [ a [ class "filters__item filters__item--selected", href "#" ]
            [ span [ class "filters__item-name" ] [ text "Inbox" ]
            ]
        , a [ class "filters__item", href "#" ]
            [ span [ class "filters__item-name" ] [ text "Everything" ]
            ]
        , a [ class "filters__item", href "#" ]
            [ span [ class "filters__item-name" ] [ text "Drafts" ]
            ]
        ]


usersList : Model -> Html Msg
usersList model =
    div [ class "users-list" ]
        [ a [ class "users-list__item", href "#" ]
            [ span [ class "state-indicator state-indicator--available" ] []
            , span [ class "users-list__name" ] [ text "Tiffany Reimer" ]
            ]
        , a [ class "users-list__item", href "#" ]
            [ span [ class "state-indicator state-indicator--focus" ] []
            , span [ class "users-list__name" ] [ text "Kelli Lowe" ]
            ]
        , a [ class "users-list__item users-list__item--offline", href "#" ]
            [ span [ class "state-indicator state-indicator--offline" ] []
            , span [ class "users-list__name" ] [ text "Joe Slacker" ]
            ]
        ]
