module OffsetPagination exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import OffsetConnection exposing (OffsetConnection)
import Route exposing (Route)
import View.Helpers exposing (viewIf)



-- API


view : OffsetConnection a -> Route -> Route -> Html msg
view conn prevRoute nextRoute =
    div [ class "flex justify-center items-center" ]
        [ prevButton prevRoute (OffsetConnection.hasPreviousPage conn)
        , nextButton nextRoute (OffsetConnection.hasNextPage conn)
        ]



-- INTERNAL


prevButton : Route -> Bool -> Html msg
prevButton prevRoute hasPrevPage =
    if hasPrevPage then
        a
            [ Route.href prevRoute
            , class "tooltip tooltip-bottom flex items-center justify-center w-9 h-9 mr-2 rounded-full bg-transparent hover:bg-grey-light transition-bg"
            , attribute "data-tooltip" "Previous"
            ]
            [ Icons.arrowLeft Icons.On
            ]

    else
        text ""


nextButton : Route -> Bool -> Html msg
nextButton nextRoute hasNextPage =
    if hasNextPage then
        a
            [ Route.href nextRoute
            , class "tooltip tooltip-bottom flex items-center justify-center w-9 h-9 ml-2 rounded-full bg-transparent hover:bg-grey-light transition-bg"
            , attribute "data-tooltip" "Next"
            ]
            [ Icons.arrowRight Icons.On
            ]

    else
        text ""
