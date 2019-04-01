module PrivacyFilter exposing (PrivacyFilter(..), fromQuery, toEnum, toQuery)


type PrivacyFilter
    = All
    | Direct


fromQuery : Maybe String -> PrivacyFilter
fromQuery value =
    case value of
        Just "direct" ->
            Direct

        _ ->
            All


toQuery : PrivacyFilter -> Maybe String
toQuery value =
    case value of
        All ->
            Nothing

        Direct ->
            Just "direct"


toEnum : PrivacyFilter -> String
toEnum value =
    case value of
        All ->
            "ALL"

        Direct ->
            "DIRECT"
