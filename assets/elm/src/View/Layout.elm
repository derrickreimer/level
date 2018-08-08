module View.Layout exposing (userLayout)

import Html exposing (..)
import Html.Attributes exposing (..)
import Avatar
import Data.User as User exposing (User)
import Icons
import Lazy exposing (Lazy(..))
import View.Helpers exposing (displayName)


-- VIEWS


userLayout : Lazy User -> Html msg -> Html msg
userLayout lazyUser bodyView =
    div [ class "container mx-auto p-6" ]
        [ div [ class "flex pb-16 sm:pb-16 items-center" ]
            [ a [ href "/spaces", class "logo logo-sm" ]
                [ Icons.logo ]
            , div [ class "flex flex-grow justify-end" ]
                [ currentUserView lazyUser ]
            ]
        , bodyView
        ]



-- INTERNAL


currentUserView : Lazy User -> Html msg
currentUserView lazyUser =
    case lazyUser of
        Loaded user ->
            let
                userData =
                    User.getCachedData user
            in
                a [ href "#", class "flex items-center no-underline text-dusty-blue-darker" ]
                    [ div [] [ Avatar.personAvatar Avatar.Small userData ]
                    , div [ class "ml-2 text-sm leading-normal" ]
                        [ div [] [ text "Signed in as" ]
                        , div [ class "font-bold" ] [ text (displayName userData) ]
                        ]
                    ]

        NotLoaded ->
            -- This is a hack to prevent any vertical shifting when the actual user is loaded
            div [ class "text-sm leading-normal invisible" ]
                [ div [] [ text "Signed in as" ]
                , div [] [ text "(loading)" ]
                ]
