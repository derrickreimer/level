module Pagination exposing (view)

import Connection exposing (Connection, endCursor, hasNextPage, hasPreviousPage, startCursor)
import Html exposing (..)
import Html.Attributes exposing (..)
import Icons
import Route exposing (Route)
import View.Helpers exposing (viewIf)



-- API


view : Connection a -> (String -> Route) -> (String -> Route) -> Html msg
view conn toPrev toNext =
    div [ class "flex justify-center items-center" ]
        [ prevButton toPrev (hasPreviousPage conn) (startCursor conn)
        , nextButton toNext (hasNextPage conn) (endCursor conn)
        ]



-- INTERNAL


prevButton : (String -> Route) -> Bool -> Maybe String -> Html msg
prevButton toPrev hasPrevPage maybeCursor =
    if hasPrevPage then
        case maybeCursor of
            Just cursor ->
                a [ Route.href (toPrev cursor), class "mr-2" ] [ Icons.arrowLeft Icons.On ]

            Nothing ->
                text ""

    else
        div [ class "mr-2" ] [ Icons.arrowLeft Icons.Off ]


nextButton : (String -> Route) -> Bool -> Maybe String -> Html msg
nextButton toNext hasNextPage maybeCursor =
    if hasNextPage then
        case maybeCursor of
            Just cursor ->
                a [ Route.href (toNext cursor), class "ml-2" ] [ Icons.arrowRight Icons.On ]

            Nothing ->
                text ""

    else
        div [ class "ml-2" ] [ Icons.arrowRight Icons.Off ]
