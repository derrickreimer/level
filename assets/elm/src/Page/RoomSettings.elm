module Page.RoomSettings exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http
import Task exposing (Task)
import Data.Room exposing (Room)
import Data.Session exposing (Session)
import Data.ValidationError exposing (ValidationError, errorsFor)
import Mutation.UpdateRoom as UpdateRoom
import Query.RoomSettings
import Util exposing (onEnter)


-- MODEL


type alias Model =
    { id : String
    , name : String
    , description : String
    , subscriberPolicy : Data.Room.SubscriberPolicy
    , isSubmitting : Bool
    , errors : List ValidationError
    }


{-| Builds a Task to fetch a room by slug.
-}
fetchRoom : Session -> String -> Task Http.Error Query.RoomSettings.Response
fetchRoom session slug =
    Query.RoomSettings.request session.apiToken (Query.RoomSettings.Params slug)
        |> Http.toTask


{-| Builds the initial model for the page.
-}
buildModel : Room -> Model
buildModel room =
    Model room.id room.name room.description room.subscriberPolicy False []


{-| Determines whether the form is able to be submitted.
-}
isSubmittable : Model -> Bool
isSubmittable model =
    model.isSubmitting == False



-- UPDATE


type Msg
    = NameChanged String
    | DescriptionChanged String
    | PrivacyToggled
    | Submit
    | Submitted (Result Http.Error UpdateRoom.Response)


update : Msg -> Session -> Model -> ( Model, Cmd Msg )
update msg session model =
    case msg of
        NameChanged val ->
            ( { model | name = val }, Cmd.none )

        DescriptionChanged val ->
            ( { model | description = val }, Cmd.none )

        PrivacyToggled ->
            if model.subscriberPolicy == Data.Room.InviteOnly then
                ( { model | subscriberPolicy = Data.Room.Public }, Cmd.none )
            else
                ( { model | subscriberPolicy = Data.Room.InviteOnly }, Cmd.none )

        Submit ->
            let
                request =
                    UpdateRoom.request session.apiToken <|
                        UpdateRoom.Params model.id model.name model.description model.subscriberPolicy
            in
                if isSubmittable model then
                    ( { model | isSubmitting = True }
                    , Http.send Submitted request
                    )
                else
                    ( model, Cmd.none )

        Submitted (Ok (UpdateRoom.Success room)) ->
            ( { model | isSubmitting = False }, Cmd.none )

        Submitted (Ok (UpdateRoom.Invalid errors)) ->
            ( { model | errors = errors, isSubmitting = False }, Cmd.none )

        Submitted (Err _) ->
            -- TODO: something unexpected went wrong - figure out best way to handle?
            ( { model | isSubmitting = False }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "main", class "main" ]
        [ div [ class "cform" ]
            [ div [ class "cform__header cform__header" ]
                [ h2 [ class "cform__heading" ] [ text "Room Settings" ]
                ]
            , div [ class "cform__form" ]
                [ inputField "name" "Room Name" model.name NameChanged model
                , inputField "description" "Description" model.description DescriptionChanged model
                , div [ class "form-field" ]
                    [ div [ class "checkbox-toggle" ]
                        [ input
                            [ type_ "checkbox"
                            , id "private"
                            , checked (model.subscriberPolicy == Data.Room.InviteOnly)
                            , onClick PrivacyToggled
                            ]
                            []
                        , label [ class "checkbox-toggle__label", for "private" ]
                            [ span [ class "checkbox-toggle__switch" ] []
                            , text "Private (by invite only)"
                            ]
                        ]
                    ]
                , div [ class "form-controls" ]
                    [ input
                        [ type_ "submit"
                        , value "Save Settings"
                        , class "button button--primary button--large"
                        , disabled (not <| isSubmittable model)
                        , onClick Submit
                        ]
                        []
                    ]
                ]
            ]
        ]


inputField : String -> String -> String -> (String -> Msg) -> Model -> Html Msg
inputField fieldName labelText fieldValue inputMsg model =
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
                [ type_ "text"
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
