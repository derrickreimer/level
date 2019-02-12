module LastActivityFilter exposing (LastActivityFilter(..), fromQuery, toEnum, toQuery)


type LastActivityFilter
    = All
    | Today


fromQuery : Maybe String -> LastActivityFilter
fromQuery value =
    case value of
        Just "today" ->
            Today

        _ ->
            All


toQuery : LastActivityFilter -> Maybe String
toQuery value =
    case value of
        All ->
            Nothing

        Today ->
            Just "today"


toEnum : LastActivityFilter -> String
toEnum value =
    case value of
        All ->
            "ALL"

        Today ->
            "TODAY"
