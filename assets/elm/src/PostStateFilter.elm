module PostStateFilter exposing (PostStateFilter(..), toEnum)


type PostStateFilter
    = Open
    | Closed
    | All


toEnum : PostStateFilter -> String
toEnum value =
    case value of
        Open ->
            "OPEN"

        Closed ->
            "CLOSED"

        All ->
            "ALL"
