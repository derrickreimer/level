module Page.Room exposing (Model, Msg, fetchRoom, buildModel, view)

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


type alias Composer =
    { body : String
    }


type alias Model =
    { room : Room
    , composer : Composer
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
    Model data.room (Composer "")



-- UPDATE


type Msg
    = ComposerBodyChanged String



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
                    [ text model.composer.body ]
                ]
            , div [ class "composer__controls" ]
                [ button [ class "button button--primary" ] [ text "Send Message" ] ]
            ]
        ]
