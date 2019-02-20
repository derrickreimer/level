module PostStateFilter exposing (PostStateFilter(..), fromQuery, toEnum, toQuery)


type PostStateFilter
    = Open
    | Closed
    | All


fromQuery : Maybe String -> PostStateFilter
fromQuery value =
    case value of
        Just "open" ->
            Open

        Just "closed" ->
            Closed

        _ ->
            All


toQuery : PostStateFilter -> Maybe String
toQuery value =
    case value of
        Open ->
            Just "open"

        Closed ->
            Just "closed"

        All ->
            Nothing


toEnum : PostStateFilter -> String
toEnum value =
    case value of
        Open ->
            "OPEN"

        Closed ->
            "CLOSED"

        All ->
            "ALL"
