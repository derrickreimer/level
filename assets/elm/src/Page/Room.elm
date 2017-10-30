module Page.Room exposing (Model, Msg, fetchRoom, buildModel, view, update)

{-| Viewing an particular room.
-}

import Task exposing (Task)
import Http
import Html exposing (..)
import Html.Events exposing (onInput)
import Html.Attributes exposing (..)
import Data.Room exposing (Room)
import Data.Session exposing (Session)
import Query.Room


-- MODEL


type alias Model =
    { room : Room
    , composerBody : String
    }


{-| Builds a Task to fetch a room by slug.
-}
fetchRoom : Session -> String -> Task Http.Error Query.Room.Response
fetchRoom session slug =
    Query.Room.request session.apiToken (Query.Room.Params slug)
        |> Http.toTask


{-| Builds a model for this page based on the response from initial page request.
-}
buildModel : Query.Room.Data -> Model
buildModel data =
    Model data.room ""



-- UPDATE


type Msg
    = ComposerBodyChanged String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ComposerBodyChanged newBody ->
            ( { model | composerBody = newBody }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "room" ]
        [ div [ class "page-head" ]
            [ h2 [ class "page-head__name" ] [ text model.room.name ]
            , p [ class "page-head__description" ] [ text model.room.description ]
            ]
        , div [ class "composer" ]
            [ div [ class "composer__body" ]
                [ textarea
                    [ class "text-field text-field--muted textarea composer__body-field"
                    , onInput ComposerBodyChanged
                    ]
                    [ text model.composerBody ]
                ]
            , div [ class "composer__controls" ]
                [ button [ class "button button--primary", disabled (isSendDisabled model) ] [ text "Send Message" ] ]
            ]
        ]


{-| Determines if the "Send Message" button should be disabled.

    isSendDisabled { composer = { body = "" } } == True
    isSendDisabled { composer = { body = "I have some text" } } == False

-}
isSendDisabled : Model -> Bool
isSendDisabled model =
    model.composerBody == ""
