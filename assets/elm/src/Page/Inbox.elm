module Page.Inbox exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- UPDATE


type Msg
    = Loaded



-- VIEW


view : Html Msg
view =
    div [ class "mx-56" ]
        [ div [ class "mx-auto pt-4 max-w-90 leading-normal text-dusty-blue-darker" ]
            [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text "Inbox" ]
            ]
        ]
