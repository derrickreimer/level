module Page.Inbox exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- UPDATE


type Msg
    = Loaded



-- VIEW


view : Html Msg
view =
    div [ class "mx-48" ]
        [ div [ class "mx-auto py-24 max-w-430px leading-normal text-dusty-blue-darker" ]
            [ h2 [ class "mb-4 font-extrabold text-2xl" ] [ text "Welcome to Level, Derrick!" ]
            , p [ class "mb-4" ] [ text "We're glad you're here." ]
            , p [] [ text "To kick things off, let’s create some groups. A group can be used to organize a team or as a place to discuss a particular topic." ]
            ]
        ]
