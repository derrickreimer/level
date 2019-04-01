module FollowingStateFilter exposing (FollowingStateFilter(..), fromQuery, toEnum, toQuery)


type FollowingStateFilter
    = All
    | Following


fromQuery : Maybe String -> FollowingStateFilter
fromQuery value =
    case value of
        Just "following" ->
            Following

        _ ->
            All


toQuery : FollowingStateFilter -> Maybe String
toQuery value =
    case value of
        All ->
            Nothing

        Following ->
            Just "following"


toEnum : FollowingStateFilter -> String
toEnum value =
    case value of
        All ->
            "ALL"

        Following ->
            "IS_FOLLOWING"
