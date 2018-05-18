module Page.Group exposing (..)

import Dom exposing (focus)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline
import Task exposing (Task)
import Avatar exposing (userAvatar)
import Data.Group exposing (Group, groupDecoder)
import Data.User exposing (User)
import GraphQL
import Session exposing (Session)


-- MODEL


type alias Model =
    { group : Group
    , user : User
    }



-- INIT


init : User -> String -> String -> Session -> Task Session.Error ( Session, Model )
init user spaceId groupId session =
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
        GraphQL.request query (Just variables) (decoder user)
            |> Session.request session


decoder : User -> Decode.Decoder Model
decoder user =
    Decode.at [ "data", "space" ] <|
        (Pipeline.decode Model
            |> Pipeline.custom (Decode.at [ "group" ] groupDecoder)
            |> Pipeline.custom (Decode.succeed user)
        )


initialized : Cmd Msg
initialized =
    setFocus "post-composer"



-- UPDATE


type Msg
    = NoOp


setFocus : String -> Cmd Msg
setFocus id =
    Task.attempt (always NoOp) <| focus id



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "mx-56" ]
        [ div [ class "mx-auto pt-4 max-w-90 leading-normal" ]
            [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text model.group.name ]
            , label [ class "composer" ]
                [ div [ class "flex" ]
                    [ div [ class "flex-no-shrink mr-2" ] [ userAvatar Avatar.Medium model.user ]
                    , div [ class "flex-grow" ]
                        [ textarea [ id "post-composer", class "p-2 w-full no-outline bg-transparent text-dusty-blue-darker resize-none", placeholder "Type something..." ] []
                        , div [ class "flex justify-end" ]
                            [ button [ class "btn btn-blue btn-sm" ] [ text ("Post to " ++ model.group.name) ] ]
                        ]
                    ]
                ]
            ]
        ]
