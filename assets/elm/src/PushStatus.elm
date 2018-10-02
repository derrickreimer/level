module PushStatus exposing (PushStatus, getIsSubscribed, init, setIsSubscribed, setNotSubscribed)


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
