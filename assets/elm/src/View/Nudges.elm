module View.Nudges exposing (Config, desktopView, mobileView)

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


desktopView : Config msg -> Html msg
desktopView config =
    div []
        [ div [ class "mb-8 flex flex-no-wrap" ] (List.indexedMap (tile config 2) morningIntervals ++ List.indexedMap (tile config 2) afternoonIntervals)
        , p [ class "text-sm text-dusty-blue-dark" ] [ text <| "In the " ++ config.timeZone ++ " time zone." ]
        ]


mobileView : Config msg -> Html msg
mobileView config =
    div [ style "max-width" "300px" ]
        [ div [ class "my-8 mb-16 flex" ] (List.indexedMap (tile config 2) morningIntervals)
        , div [ class "my-8 flex" ] (List.indexedMap (tile config 2) afternoonIntervals)
        , p [ class "text-sm text-dusty-blue-dark" ] [ text <| "In the " ++ config.timeZone ++ " time zone." ]
        ]


tile : Config msg -> Int -> Int -> Int -> Html msg
tile config labelEvery idx minute =
    let
        isActive =
            hasNudgeAt minute config
    in
    button
        [ classList
            [ ( "mr-1 tooltip tooltip-bottom text-center flex-grow rounded h-12 no-outline", True )
            , ( "bg-grey hover:bg-grey-dark", not isActive )
            , ( "bg-blue", isActive )
            ]
        , style "transition" "background-color 0.2s ease"
        , onClick (config.toggleMsg minute)
        , attribute "data-tooltip" (Minutes.toLongString minute)
        ]
        [ viewIf (modBy labelEvery idx == 0) <|
            div
                [ class "absolute text-xs text-dusty-blue font-bold pin-l-50"
                , style "bottom" "-20px"
                , style "transform" "translateX(-50%)"
                ]
                [ text (Minutes.toString minute) ]
        ]



-- PRIVATE


morningIntervals : List Int
morningIntervals =
    List.range 10 23
        |> List.map ((*) 30)


afternoonIntervals : List Int
afternoonIntervals =
    List.range 24 37
        |> List.map ((*) 30)


hasNudgeAt : Int -> Config msg -> Bool
hasNudgeAt minute config =
    List.any (\nudge -> Nudge.minute nudge == minute) config.nudges
