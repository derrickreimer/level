module PushStatus exposing (PushStatus, bannerView, getIsSubscribed, init, setIsSubscribed, setNotSubscribed)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import View.Helpers exposing (viewUnless)


type PushStatus
    = PushStatus Internal


type alias Internal =
    { isSupported : Bool
    , isSubscribed : Maybe Bool
    }



-- API


init : Bool -> PushStatus
init isSupported =
    PushStatus (Internal isSupported Nothing)


setIsSubscribed : PushStatus -> PushStatus
setIsSubscribed (PushStatus internal) =
    PushStatus { internal | isSubscribed = Just True }


setNotSubscribed : PushStatus -> PushStatus
setNotSubscribed (PushStatus internal) =
    PushStatus { internal | isSubscribed = Just False }


getIsSubscribed : PushStatus -> Maybe Bool
getIsSubscribed (PushStatus internal) =
    internal.isSubscribed



-- VIEW


bannerView : PushStatus -> msg -> Html msg
bannerView pushStatus onClicked =
    viewUnless (getIsSubscribed pushStatus |> Maybe.withDefault True) <|
        div [ class "mx-3 mb-3 px-4 py-3 flex items-center bg-green-lightest border-b-2 border-green text-green-dark text-md font-bold" ]
            [ div [ class "flex-grow" ] [ text "Allow Level to send you push notifications." ]
            , button [ class "btn btn-sm btn-green", onClick onClicked ] [ text "Allow" ]
            ]
