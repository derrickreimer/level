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
        a [ Route.href prevRoute, class "mr-2" ] [ Icons.arrowLeft Icons.On ]

    else
        div [ class "mr-2" ] [ Icons.arrowLeft Icons.Off ]


nextButton : Route -> Bool -> Html msg
nextButton nextRoute hasNextPage =
    if hasNextPage then
        a [ Route.href nextRoute, class "ml-2" ] [ Icons.arrowRight Icons.On ]

    else
        div [ class "ml-2" ] [ Icons.arrowRight Icons.Off ]
