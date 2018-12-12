module View.Nudges exposing (Config, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Minutes
import Nudge exposing (Nudge)
import View.Helpers exposing (viewIf)



-- CONFIG


type alias Config msg =
    { toggleMsg : Int -> msg
    , nudges : List Nudge
    , timeZone : String
    }



-- VIEW


view : Config msg -> Html msg
view config =
    div []
        [ div [ class "mb-8 flex flex-no-wrap" ] (List.indexedMap (tile config) intervals)
        , p [ class "text-sm text-dusty-blue-dark" ] [ text <| "In the " ++ config.timeZone ++ " time zone." ]
        ]


tile : Config msg -> Int -> Int -> Html msg
tile config idx minute =
    let
        isActive =
            hasNudgeAt minute config
    in
    button
        [ classList
            [ ( "mr-1 relative text-center flex-grow rounded h-12 no-outline", True )
            , ( "bg-grey hover:bg-grey-dark", not isActive )
            , ( "bg-blue", isActive )
            ]
        , style "transition" "background-color 0.2s ease"
        , onClick (config.toggleMsg minute)
        ]
        [ viewIf (modBy 4 idx == 0) <|
            div
                [ class "absolute text-xs text-dusty-blue font-bold pin-l-50"
                , style "bottom" "-20px"
                , style "transform" "translateX(-50%)"
                ]
                [ text (Minutes.toString minute) ]
        , div
            [ class "absolute p-2 text-xs font-bold text-white bg-dusty-blue-darker rounded pin-l-50 tooltip"
            , style "bottom" "-35px"
            , style "transform" "translateX(-50%)"
            ]
            [ text (Minutes.toString minute)
            ]
        ]



-- PRIVATE


intervals : List Int
intervals =
    List.range 12 36
        |> List.map ((*) 30)


hasNudgeAt : Int -> Config msg -> Bool
hasNudgeAt minute config =
    List.any (\nudge -> Nudge.minute nudge == minute) config.nudges
