module Page.Inbox exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Avatar exposing (personAvatar)
import Data.SpaceUser exposing (SpaceUser)
import ViewHelpers exposing (displayName)


-- UPDATE


type Msg
    = Loaded



-- VIEW


view : List SpaceUser -> Html Msg
view featuredUsers =
    div [ class "mx-56" ]
        [ div [ class "mx-auto max-w-90 leading-normal" ]
            [ div [ class "group-header sticky pin-t border-b py-4 bg-white z-50" ]
                [ div [ class "flex items-center" ]
                    [ h2 [ class "mb-6 font-extrabold text-2xl" ] [ text "Inbox" ]
                    ]
                ]
            , sidebarView featuredUsers
            ]
        ]


sidebarView : List SpaceUser -> Html Msg
sidebarView featuredUsers =
    div [ class "fixed pin-t pin-r w-56 mt-3 py-2 pl-6 border-l min-h-half" ]
        [ h3 [ class "mb-3 text-base" ] [ text "Directory" ]
        , div [] <| List.map userItemView featuredUsers
        ]


userItemView : SpaceUser -> Html Msg
userItemView user =
    div [ class "flex items-center pr-4 mb-px" ]
        [ div [ class "flex-no-shrink mr-2" ] [ personAvatar Avatar.Tiny user ]
        , div [ class "flex-grow text-sm truncate" ] [ text <| displayName user ]
        ]
