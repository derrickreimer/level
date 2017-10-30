module Page.Room exposing (Model, Msg, fetchRoom, view)

{-| Viewing an particular room.
-}

import Task exposing (Task)
import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Data.Room exposing (Room)
import Data.Session exposing (Session)
import Query.Room


-- MODEL


type alias Model =
    { room : Room
    }


{-| Build a task to fetch a room by slug.
-}
fetchRoom : Session -> String -> Task Http.Error Query.Room.Response
fetchRoom session slug =
    Query.Room.request session.apiToken (Query.Room.Params slug)
        |> Http.toTask



-- UPDATE


type Msg
    = Undefined



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
                [ textarea [ class "text-field text-field--muted textarea composer__body-field" ] []
                ]
            , div [ class "composer__controls" ]
                [ button [ class "button button--primary" ] [ text "Send Message" ] ]
            ]
        ]
