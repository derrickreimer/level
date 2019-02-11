module InboxStateFilter exposing (InboxStateFilter(..), toEnum)


type InboxStateFilter
    = Undismissed
    | Dismissed
    | All


toEnum : InboxStateFilter -> String
toEnum value =
    case value of
        Undismissed ->
            "UNDISMISSED"

        Dismissed ->
            "DISMISSED"

        All ->
            "ALL"
