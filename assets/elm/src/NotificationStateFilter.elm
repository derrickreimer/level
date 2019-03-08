module NotificationStateFilter exposing (NotificationStateFilter(..), toEnum)


type NotificationStateFilter
    = Undismissed
    | Dismissed
    | All


toEnum : NotificationStateFilter -> String
toEnum value =
    case value of
        Undismissed ->
            "UNDISMISSED"

        Dismissed ->
            "DISMISSED"

        All ->
            "ALL"
