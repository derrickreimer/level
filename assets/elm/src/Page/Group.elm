module Page.Group exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline
import Task exposing (Task)
import Avatar exposing (texitar)
import Data.Group exposing (Group, groupDecoder)
import GraphQL
import Session exposing (Session)


-- MODEL


type alias Model =
    { group : Group
    }



-- INIT


init : String -> String -> Session -> Task Session.Error ( Session, Model )
init spaceId groupId session =
    let
        query =
            """
              query GroupInit(
                $spaceId: ID!
                $groupId: ID!
              ) {
                space(id: $spaceId) {
                  group(id: $groupId) {
                    id
                    name
                  }
                }
              }
            """

        variables =
            Encode.object
                [ ( "spaceId", Encode.string spaceId )
                , ( "groupId", Encode.string groupId )
                ]
    in
        GraphQL.request query (Just variables) decoder
            |> Session.request session


decoder : Decode.Decoder Model
decoder =
    Decode.at [ "data", "space" ] <|
        (Pipeline.decode Model
            |> Pipeline.custom (Decode.at [ "group" ] groupDecoder)
        )



-- UPDATE


type Msg
    = NoOp



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto pt-4 max-w-90 leading-normal text-dusty-blue-darker" ]
            [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text model.group.name ]
            , div [ class "p-4 bg-grey-light w-full rounded" ]
                [ texitar Avatar.Medium "D" ]
            ]
        ]
